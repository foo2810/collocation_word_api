# Collocation Word API

## What is this?

API for searching Japanese collocation words.

## Features

This API uses the Word2Vec model to search for collocations. The parameters of the Word2Vec model are publicly available at the [TOHOKU NLP LAB](https://www.cl.ecei.tohoku.ac.jp/~m-suzuki/jawiki_vector/).

## How to install?

### Prerequisites
- Amazon Simple Storage Service (S3) already has had created.
- You already have sufficient access to AWS resources. (Administrative privileges recommended)
- Linux environment is available.

### Installation
First, you have to configure installation setup. Please rewrite following shell variables in `build.sh` and `deploy.sh`.

```sh
workdir=/path/to/work/directory   # Work directory (absolute path)
model_name=model.pkl              # Model file name
```

Then, execute `build.sh`.

```sh
bash build.sh
```

Build API on AWS using the deployment package and model files created in the working directory.

There are two deployment methods.
1. Deploy on Lambda using `AWS Management Console` manually. (Now recommended)
2. Deploy using `deploy.sh` (Now deprecated)

If you deploy using `deploy.sh`, please rewrite shell variables in `deploy.sh`.

```sh
# Onlu build.sh
aws_lambda_func_name=collocation_word_api   # Lambda name
aws_s3_bucket=your-bucket-name              # Your bucket name of S3
aws_region=region-name                      # Region
aws_id=your-account-id                      # Account ID
```


## Load map
- [x] Create prototype
- [ ] Debug
- [ ] Add error handling of `deploy.sh`
- [ ] Improve search performance 
