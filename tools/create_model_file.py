"""
Create pickled model file
"""

import sys
import pickle
from pathlib import Path
from gensim.models import KeyedVectors

def load_model(model_path:Path):
    model = KeyedVectors.load_word2vec_format(model_path, binary=True)
    return model

def main():
    args = sys.argv
    if len(args) != 3:
        sys.stderr.write('Usage: python create_pickled_model.py model_path output_path\n')
        sys.exit(1)

    model_path = Path(args[1])
    if not model_path.exists():
        sys.stderr.write(f' > Error: {model_path} not found\n')
        sys.exit(1)

    output_path = Path(args[2])
    model = load_model(model_path)
    with output_path.open('wb') as fp:
        pickle.dump(model, fp, protocol=4)

if __name__ == '__main__':
    main()
