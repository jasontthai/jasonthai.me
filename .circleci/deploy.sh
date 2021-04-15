git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"

export COMMIT_MESSAGE=\"$(git log --format=oneline -1 --pretty=format:'%h - %B')\"

echo $COMMIT_MESSAGE

git clone $GITHUB_PAGE_REPOSITORY_URL destination
cd destination

git checkout master
git pull origin master

find . -maxdepth 1 ! -name '_site' ! -name '.git' ! -name '.gitignore' -exec rm -rf {} \;
rsync -avz ../_site/ json@$SERVER_IP:/var/www/jasonthai/
rsync -avz ../_site/assets json@$SERVER_IP:/var/www/cdn/
mv ../_site/* .

git add -fA
git commit --allow-empty -m "$COMMIT_MESSAGE"
git push -f origin master

echo "Deployed successfully"