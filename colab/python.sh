cd ~/dev || return
git clone https://github.com/hemanta212/nepali-news-portal-kbd kbd/
cd kbd/ || return
git config --global credential.helper store
git push origin master
cd || return

cd ~/dev || return
git clone https://github.com/hemanta212/hello-manim
git clone https://github.com/hemanta212/blogger-cli
git clone https://github.com/hemanta212/news_api
git clone https://github.com/hemanta212/meme_khani_api
git clone https://github.com/hemanta212/status
git clone https://github.com/hemanta212/django-rest
git clone https://github.com/hemanta212/raft-python
git clone https://github.com/hemanta212/flask-rest-api

curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py -o ~/poetry.py
python ~/poetry.py -y
poetry config virtualenvs.in-project true
poetry init -n -q
poetry add requests ptpython pylint black python-language-server isort rich
