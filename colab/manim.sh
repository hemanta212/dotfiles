#sudo apt-add-repository ppa:jonathonf/texlive-2019 && sudo apt-get update  && sudo apt-get upgrade
sudo apt-get install python3-opencv libcairo2-dev texlive texlive-latex-extra texlive-fonts-extra \
texlive-latex-recommended texlive-science texlive-fonts-extra tipa

cd dev/hello-manim
poetry install
# poetry add ./manim
cd manim/ && poetry run python setup.py develop && cd ..
#cp -r manim/manimlib/* .venv/lib/python3.7/site-packages/manimlib/