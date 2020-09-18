# Save tmux things
cd ~/.tmux/
zip resurrector resurrect/ -r 
cd ~/dev/dotfiles
git checkout gh-pages
mv resurrector.zip ~/dev/dotfiles/colab/resurrect.zip
git commit -a -m "save ressurect file"
git config credential.helper store
git push origin gh-pages
