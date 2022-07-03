#!/bin/bash

set -e

workdir=/path/to/work/directory   # absolute path
package_dir=${workdir}/package
function_path=functions/main/lambda_function.py
package_archive_name=package.zip
model_dir=${workdir}/model
model_name=model.pkl

# Check path
if ! expr "$workdir" : "/.*" > /dev/null; then
    echo "workdir must be absolute path" 1>&2
    exit 1
fi

# Create work directory
mkdir -p $workdir $package_dir

# Copy lambda_function to work directory
if [ ! -e $function_path ]; then 
    echo "$function_path not exist" 1>&2
    exit 1
fi
cp $function_path $package_dir/

# Install dependency packages into work directory
pip install gensim -t ${package_dir}/


# Shrink size of packages without scipy
pname_list=`ls -d */ $package_dir | grep -v scipy`
for pname in $pname_list
do
    echo $pname
    find $pname -type f -name "*.so" | xargs strip
done

# Archive function and packages
zip -r $workdir/$package_archive_name ${package_dir}/*

# Fetch trained word2vec model
mkdir -p $model_dir 
curl https://www.cl.ecei.tohoku.ac.jp/~m-suzuki/jawiki_vector/data/20170201.tar.bz2 -o ${model_dir}/20170201.tar.bz2
tar -C $model_dir -xjvf ${model_dir}/20170201.tar.bz2 entity_vector/entity_vector.model.bin 
#tar xjvf ${model_dir}/20170201.tar.bz2 -C $model_dir

# Create pickle of word2vec model
export PYTHONPATH=${package_dir}:$PYTHONPATH
python tools/create_model_file.py ${model_dir}/entity_vector/entity_vector.model.bin ${model_dir}/model.pkl
rm -rf ${model_dir}/entity_vector ${model_dir}/20170201.tar.bz2

