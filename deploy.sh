#!/bin/bash
# Deploy bigoil.net to S3
# Usage: ./deploy.sh

echo "Deploying bigoil.net to S3..."

aws s3 sync . s3://bigoil.net \
    --exclude ".git/*" \
    --exclude ".DS_Store" \
    --exclude "*.md" \
    --exclude "*.json" \
    --exclude "deploy.sh" \
    --exclude ".gitignore"

echo ""
echo "Done! Site live at:"
echo "  http://bigoil.net.s3-website-us-east-1.amazonaws.com"
echo ""
echo "To add files, just drop them in this folder and run ./deploy.sh"
