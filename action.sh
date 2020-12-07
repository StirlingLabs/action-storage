initialize-branch-content(){
	# Extract project name from remote url
	github_project=$(git remote get-url origin | sed 's/https:\/\/[a-zA-Z\.]*\/\([a-zA-Z0-9\.\/\-]*\)\.git/\1/g')

	# Add a README to explain the purpose of this branch.
	cat > README.md <<-EOF
	# Storage branch

	> Branch used to store statics files generated by GitHub actions.

	Can be used to permanently store coverage reports, badges, etc...
	Resulting files can then be referenced in
	* markdown documentation
	* issues
	* pull requests
	* or anywhere else.

	Here is for example the link to the raw README.md file :

	https://raw.githubusercontent.com/${github_project}/${storage_branch}/README.md
	EOF
}


create-storage-branch(){
	# Create orphan storage branch
	git checkout --orphan $storage_branch
	# Add default content to the branch
	initialize-branch-content
	# Create initial commit and push the new branch to remote
	git add . ; git commit -m "Create storage branch" ; git push -u origin $storage_branch
}


checkout-storage-branch(){
	# First arg variable will contain branch_path
	declare -n branch_path=$1

	# get default remote url
	remote_url=$(git remote get-url origin)

	# clone repo in another folder (to avoid mutate current folder's state)
	branch_path=/tmp/$storage_branch-$(date +%s)
	mkdir -p $branch_path && cd $branch_path

	git init
	git remote add origin $remote_url
	
	# create storage if it doesn't exists
	git fetch origin $storage_branch || create-storage-branch

	# checkout storage branch
	git checkout $storage_branch

	# Go back to last working directory and return reference of the created repo
	cd -
	echo $branch_path
}


add-to-storage(){
	storage_local_path="$1"
	abs_dst_path=$storage_local_path/$dst
	mkdir -p $(dirname $abs_dst_path)
	cp -r $src $abs_dst_path

	cd $storage_local_path
	git add .
	git commit -m "$message" ; git push origin $storage_branch || echo "No changes in storage"
	cd -
}


main(){
	# Configure a generic identity for the action
	git config user.email storage@github.action
	git config user.name "GitHub storage action"
	# Create checkout storage branch in another clone of the repo
	checkout-storage-branch storage_local_path
	add-to-storage $storage_local_path
	echo "Local storage path: $storage_local_path" > /dev/stderr
}

main