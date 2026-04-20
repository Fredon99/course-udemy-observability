#!/bin/bash

# Script to initialize MinIO bucket
set -e

echo "Waiting for MinIO to be ready..."
until /usr/bin/mc alias set myminio http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" 2>/dev/null; do
  echo "MinIO not ready yet, retrying..."
  sleep 2
done

echo "MinIO is ready!"

# Create bucket
echo "Creating bucket: $MINIO_BUCKET_NAME"
/usr/bin/mc mb myminio/$MINIO_BUCKET_NAME --ignore-existing

echo "Bucket $MINIO_BUCKET_NAME created successfully!"
