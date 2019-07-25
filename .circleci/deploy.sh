git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"

git clone $GITHUB_PAGE_REPOSITORY_URL destination
cd destination

git checkout master
git pull origin master

find . -maxdepth 1 ! -name '_site' ! -name '.git' ! -name '.gitignore' -exec rm -rf {} \;
mv ../_site/* .

git add -fA
git commit --allow-empty -m "$GIT_COMMIT_DESC"
git push -f origin master

echo "Deployed successfully"