curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py -o ~/poetry.py
curl -sSL https://hemanta212.github.io/blogger-cli/get_blogger.py -o ~/blogger.py
python ~/poetry.py -y
python ~/blogger.py -y 
python -m venv .ptvenv
.ptvenv/bin/python -m pip install ptpython requests 

mkdir ~/dev && cd ~/dev
git clone https://github.com/hemanta212/blogger-cli
git clone https://github.com/hemanta212/nepali-news-portal-kbd kbd/
cd kbd/
git config --global credential.helper store
git push origin master
cd ~/dev

git clone https://github.com/hemanta212/news_api
