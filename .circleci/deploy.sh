git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"

echo "export COMMIT_MESSAGE=\"$(git log --format=oneline -n 1 $CIRCLE_SHA1)\"" >> ~/.bashrc

git clone $GITHUB_PAGE_REPOSITORY_URL destination
cd destination

git checkout master
git pull origin master

find . -maxdepth 1 ! -name '_site' ! -name '.git' ! -name '.gitignore' -exec rm -rf {} \;
mv ../_site/* .

git add -fA
git commit --allow-empty -m "$COMMIT_MESSAGE"
git push -f origin master

echo "Deployed successfully"