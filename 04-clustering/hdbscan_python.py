"""Run the course HDBSCAN implementation on an X matrix exported from R."""
import argparse
import pandas as pd
import hdbscan


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_csv", help="CSV with row_id and numeric X columns")
    parser.add_argument("output_csv", help="CSV path for row-aligned labels")
    parser.add_argument("--min-cluster-size", type=int, default=20)
    args = parser.parse_args()

    frame = pd.read_csv(args.input_csv)
    row_id = frame.pop("row_id")
    X = frame.to_numpy(dtype="float64")

    clusterer = hdbscan.HDBSCAN(min_cluster_size=args.min_cluster_size)
    labels = clusterer.fit_predict(X)

    pd.DataFrame(
        {
            "row_id": row_id,
            "cluster": labels,
            "probability": clusterer.probabilities_,
            "outlier_score": clusterer.outlier_scores_,
        }
    ).to_csv(args.output_csv, index=False)


if __name__ == "__main__":
    main()