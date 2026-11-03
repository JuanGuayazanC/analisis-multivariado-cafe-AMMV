"""Standalone HDBSCAN analysis for the cleaned Arabica coffee dataset.

Run from any directory with:
    py 04-clustering/hdbscan_python.py

The feature matrix is reconstructed here in Python. This script does not receive
data or intermediate objects from the R Markdown analysis.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import hdbscan
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.preprocessing import OneHotEncoder, PowerTransformer, StandardScaler
from scipy.stats import skew


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATA = ROOT / "data" / "arabica_data_cleaned.csv"
NUMERIC_FEATURES = [
    "Aroma", "Flavor", "Aftertaste", "Acidity", "Body", "Balance",
    "Cupper.Points", "altitude_mean_meters",
]
PROFILE_FEATURES = [
    "Aroma", "Flavor", "Aftertaste", "Acidity", "Body", "Balance",
    "Cupper.Points", "Total.Cup.Points",
]
CATEGORICAL_FEATURES = ["Processing.Method", "Color", "Country.of.Origin"]


def build_feature_matrix(data_path: Path) -> tuple[pd.DataFrame, np.ndarray, np.ndarray, list[str], list[str]]:
    """Filter lots, transform numeric features, and balance numeric/dummy blocks."""
    data = pd.read_csv(data_path, low_memory=False)
    data["row_id"] = np.arange(1, len(data) + 1)
    data["altitude_mean_meters"] = pd.to_numeric(
        data["altitude_mean_meters"], errors="coerce"
    )
    data = data.loc[
        data["altitude_mean_meters"].notna()
        & data["altitude_mean_meters"].gt(0)
        & data["altitude_mean_meters"].le(3000)
    ].copy()
    data = data.dropna(subset=NUMERIC_FEATURES + PROFILE_FEATURES).reset_index(drop=True)

    numeric = data[NUMERIC_FEATURES].astype(float).copy()
    skewness = pd.Series(skew(numeric, axis=0, bias=True), index=numeric.columns)
    transform_columns = skewness.index[skewness.abs() > 1].tolist()
    if transform_columns:
        yj = PowerTransformer(method="yeo-johnson", standardize=False)
        numeric.loc[:, transform_columns] = yj.fit_transform(numeric[transform_columns])

    scaled_numeric = StandardScaler().fit_transform(numeric)
    pca = PCA(n_components=4, svd_solver="full")
    scores = pca.fit_transform(scaled_numeric)
    score_standardizer = StandardScaler()
    scores = score_standardizer.fit_transform(scores) / np.sqrt(4)

    categorical = data[CATEGORICAL_FEATURES].copy()
    for column in CATEGORICAL_FEATURES:
        values = categorical[column].astype("string").str.strip()
        categorical[column] = values.mask(values.isna() | values.eq(""), "Desconocido")
    top_origins = categorical["Country.of.Origin"].value_counts().head(5).index
    categorical["Country.of.Origin"] = categorical["Country.of.Origin"].where(
        categorical["Country.of.Origin"].isin(top_origins), "Otro"
    )
    encoder = OneHotEncoder(handle_unknown="ignore", sparse_output=False, dtype=float)
    dummies_full = encoder.fit_transform(categorical)
    # R's model.matrix(~ A + B + C - 1) creates all indicators for A and
    # treatment contrasts (first sorted level omitted) for B and C.
    all_names = encoder.get_feature_names_out(CATEGORICAL_FEATURES)
    keep_dummy = np.array([
        not (name.startswith("Color_") and name.endswith("_" + encoder.categories_[1][0]))
        and not (name.startswith("Country.of.Origin_")
                 and name.endswith("_" + encoder.categories_[2][0]))
        for name in all_names
    ])
    dummies = dummies_full[:, keep_dummy]
    X = np.column_stack((scores, dummies / np.sqrt(len(CATEGORICAL_FEATURES))))
    names = [f"PC{i}" for i in range(1, 5)] + all_names[keep_dummy].tolist()

    if len(data) != len(X) or data["row_id"].duplicated().any():
        raise ValueError("Las filas del dataset y de la matriz de clustering no están alineadas.")
    return data, X, scores, names, transform_columns


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=DEFAULT_DATA, help="Ruta al CSV limpio")
    parser.add_argument("--min-cluster-size", type=int, default=20)
    parser.add_argument("--output-dir", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--no-plot", action="store_true", help="No guardar el gráfico")
    args = parser.parse_args()
    if args.min_cluster_size < 2:
        parser.error("--min-cluster-size debe ser al menos 2")

    data, X, scores, feature_names, transform_columns = build_feature_matrix(args.data)
    model = hdbscan.HDBSCAN(min_cluster_size=args.min_cluster_size)
    labels = model.fit_predict(X)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    output = data[["row_id"] + PROFILE_FEATURES].copy()
    output["cluster"] = labels
    output["probability"] = model.probabilities_
    output["outlier_score"] = model.outlier_scores_
    labels_path = args.output_dir / "hdbscan_resultados.csv"
    output.to_csv(labels_path, index=False)

    counts = pd.Series(labels, name="cluster").value_counts().sort_index()
    summary = pd.DataFrame({"lotes": counts, "porcentaje": 100 * counts / len(labels)})
    summary.index.name = "cluster (-1 = ruido)"
    summary_path = args.output_dir / "hdbscan_tamanos.csv"
    summary.to_csv(summary_path)

    print(f"Lotes analizados: {len(data):,}")
    print(f"Matriz X: {X.shape[0]} filas × {X.shape[1]} columnas")
    print("Bloque: 4 componentes PCA + dummies de método, color y país.")
    print(f"Variables transformadas con Yeo-Johnson (|sesgo| > 1): "
          f"{', '.join(transform_columns) if transform_columns else 'ninguna'}")
    print(f"Parámetro min_cluster_size: {args.min_cluster_size}")
    print("\nTamaños de grupo (%):")
    print(summary.round(1).to_string())
    print(f"\nResultados por lote: {labels_path}")
    print(f"Resumen de tamaños: {summary_path}")
    print(f"Variables del vector X: {', '.join(feature_names)}")

    clustered = output.loc[output["cluster"] != -1]
    if not clustered.empty:
        profile = clustered.groupby("cluster")[PROFILE_FEATURES].mean().round(2)
        print("\nPromedios por cluster en escala original (ruido excluido):")
        print(profile.to_string())

    if not args.no_plot:
        plot_path = args.output_dir / "hdbscan_clusters.png"
        unique = sorted(np.unique(labels))
        palette = plt.get_cmap("tab10")
        fig, ax = plt.subplots(figsize=(10, 7))
        for i, label in enumerate(unique):
            mask = labels == label
            color = "#9ca3af" if label == -1 else palette(i % 10)
            name = "Ruido (-1)" if label == -1 else f"Cluster {label}"
            ax.scatter(scores[mask, 0], scores[mask, 1], s=25, alpha=0.72,
                       color=color, label=name, edgecolors="none")
        ax.set(title="HDBSCAN sobre la proyección PCA",
               xlabel="Componente principal 1", ylabel="Componente principal 2")
        ax.legend(title="Asignación", frameon=True)
        ax.grid(alpha=0.2)
        fig.tight_layout()
        fig.savefig(plot_path, dpi=180)
        plt.close(fig)
        print(f"Gráfico: {plot_path}")


if __name__ == "__main__":
    main()
