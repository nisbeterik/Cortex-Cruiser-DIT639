# 2025-group-06

## Add your files

- [ ] [Create](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#create-a-file) or [upload](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#upload-a-file) files
- [ ] [Add files using the command line](https://docs.gitlab.com/ee/gitlab-basics/add-file.html#add-a-file-using-the-command-line) or push an existing Git repository with the following command:

```
cd existing_repo
git remote add origin https://git.chalmers.se/courses/dit638/students/2025-group-06.git
git branch -M main
git push -uf origin main
```

## Integrate with your tools

- [ ] [Set up project integrations](https://git.chalmers.se/courses/dit638/students/2025-group-06/-/settings/integrations)

## Collaborate with your team

- [ ] [Invite team members and collaborators](https://docs.gitlab.com/ee/user/project/members/)
- [ ] [Create a new merge request](https://docs.gitlab.com/ee/user/project/merge_requests/creating_merge_requests.html)
- [ ] [Automatically close issues from merge requests](https://docs.gitlab.com/ee/user/project/issues/managing_issues.html#closing-issues-automatically)
- [ ] [Enable merge request approvals](https://docs.gitlab.com/ee/user/project/merge_requests/approvals/)
- [ ] [Set auto-merge](https://docs.gitlab.com/ee/user/project/merge_requests/merge_when_pipeline_succeeds.html)

## Test and Deploy

Use the built-in continuous integration in GitLab.

- [ ] [Get started with GitLab CI/CD](https://docs.gitlab.com/ee/ci/quick_start/)
- [ ] [Analyze your code for known vulnerabilities with Static Application Security Testing (SAST)](https://docs.gitlab.com/ee/user/application_security/sast/)
- [ ] [Deploy to Kubernetes, Amazon EC2, or Amazon ECS using Auto Deploy](https://docs.gitlab.com/ee/topics/autodevops/requirements.html)
- [ ] [Use pull-based deployments for improved Kubernetes management](https://docs.gitlab.com/ee/user/clusters/agent/)
- [ ] [Set up protected environments](https://docs.gitlab.com/ee/ci/environments/protected_environments.html)

***

## Suggestions for a good README

Every project is different, so consider which of these sections apply to yours. The sections used in the template are suggestions for most open source projects. Also keep in mind that while a README can be too long and detailed, too long is better than too short. If you think your README is too long, consider utilizing another form of documentation rather than cutting out information.

## Name
Choose a self-explaining name for your project.

## Description
Let people know what your project can do specifically. Provide context and add a link to any reference visitors might be unfamiliar with. A list of Features or a Background subsection can also be added here. If there are alternatives to your project, this is a good place to list differentiating factors.

## Requirements & Dependencies

### Preqrequisites
- The project assumes a Linux based operating system such as Ubuntu. 
The tools required to be installed on the system are:
    - g++ 
        - Any version
    - cmake
        - Version 3.2+
    - make
        - Any version
    - Docker
        - Latest version
    - wget
        - Any version
    - git
        - Any version

## How to install these tools
    - g++: sudo apt-get install build-essential
    - cmake: sudo apt-get install cmake
    - make: included in build essential
    - Docker: https://docs.docker.com/get-docker/
    - wget: sudo apt-get install wget
    - git: sudo apt-get install git
## Required files
* catch.hpp
    - download: https://github.com/catchorg/Catch2/releases/download/v2.13.10/catch.hpp)


## Cloning the repository
Open a terminal and change directory to where you want to store the repository, for example desktop.
```
mkdir dit639
cd dit639
git clone git@git.chalmers.se:courses/dit638/students/2025-group-06.git
```
## Building and excecuting in the terminal
This project uses cmake for building files. To build a file you navigate to the location of the file you want to build.
```
cd example/example.cpp
```

#### First build

```
mkdir build
cd build
cmake ..
make
```

#### When building again

```
cd build
rm -f *    #CHECK THAT YOU ARE IN THE RIGHT FOLDER!!!!
cmake ..
make
```

After you have built the file, the file is now excecutable. Make sure you are in the build folder. To excecute the file run

```
./example "arguments" 
```



## Visuals
Depending on what you are making, it can be a good idea to include screenshots or even a video (you'll frequently see GIFs rather than actual videos). Tools like ttygif can help, but check out Asciinema for a more sophisticated method.





## Authors and acknowledgment
- Martin Lidgren @marlidg
- Edvin Sanfridssson 
- Love Carlander Strandäng
- Erik Nisbet @eriknis

## License

## Creating new features

This section outlines the workflow of creating new features for the project using Git issues. These standards are to be followed throughout the duration of the project.

### Creating issues

An issue should be created based on a requirement that represents a required feature. The issue title should be a clear, concise summary of the request.

Every issue related to a feature should have at least one user story. A user story represents the need of a user that would require the feature to be implemented.

### Template for Issues

### Title

Provide a clear, concise summary of the issue.

### User Story

> As a `<replace>`, I want `<replace>` so that `<replace>`

### Short Description

Include any additional details that may not be covered in the user story or acceptance criteria.

### Acceptance Criteria

- [ ] Verify that `<replace>`
- [ ] Verify that `<replace>`

---

### Non-Feature Issues

For issues not related to a specific feature, omit the user story but keep the same template structure (Title, Short Description, and Acceptance Criteria).

### Labels

All issues should be labeled with relevant labels found in the label dropdown at issue creation.

### Feature branching

All issues regarding changes in the repo should have their own branch. The branch should be created from the issue's page in Gitlab and subsequently be named
in the format of <issue-name>-<title>.

## Fixing unexpected behavior in existing features

When working on unexpected behaviour or 'bugs', the same standard as feature development is in place. That includes, issue creation, 'feature branching' and labelling the issues correctly. Making sure the description of the unexpected behavior is clear in the issue description.
Useful labels can be 'bug' or 'refactor' depending on what work is needed.

## Commit messages

This section outlines the standard praxis for commits in the project. The aim of the chapter is to give a clear modus operandi for any developer contributing.

### Atomic Commits

- Commits should represent a single logical change
- Break larger changes into smaller commits for easier understandability
- Commit related changes meaning avoid grouping unrelated changes into the same commit

### Write Clear Commit Messages

- Start each commit with a # for the issue it relates to
- Each commit shall use imperative mood (e.g "Add feature", **NOT** "Added feature")
- Describe changes concisely and precisely ("Add.." related to adding, "Refactor..." related to refactoring etc.)

### Avoid committing Unnecessary Files

- Includes developer environment files, build files etc.

### Security Practice

- Don't commit sensitive information such as passwords, network ID's or personal data

### **Commit Message Template:**

**Git commit -m “\<#issue-number\> - \<TITLE\>” -m “More detailed description”**

* **`<#issue-number>`**: The issue the commit is connected to.
* **`<TITLE>`**: In your head, think: “If I commit this, it will...” and complete the sentence with the title. This should be a concise summary of the change.
* **`More detailed description`**: Use the second **`-m`** option to provide a detailed description if necessary.

## Merge requests & code review

This page contains the guidelines for merge requests in the StuWi project repo. The aim of the page is to give a clear conduct for both developers creating merge requests and reviewing merge requests.

### Creating Merge Requests

Merge requests are to be created once the issue/issues it resolves have been fully implemented according to their acceptance criteria. Merge requests are required when merging from a feature branch to the main branch. When creating a request, choose the standard project template as such:

---

**Description** <br />  
`_Description about the merge. what it affects and what you have done_`

**Related issue**   
Closes issue #X 

**Authors & Co-Authors** <br />
_Authors_

---

Once the correct details have been filled out, assign yourself as the responsible for the request and a project member who have not made a commit in the merge request as the reviewer.

### Reviewing Merge Requests

As the reviewer of a merge request, your job is to review the changes made and make sure they adhere to the following:

- Implements the correct features
- Satisfies all the acceptance criteria
- Maintains high code quality
- Check for any potential bugs

**Feedback**

After reviewing, comment on the merge request with feedback. Communication should remain respectful, clear and constructive. When the request responsible have addressed the feedback with potential additional changes, review the new changes and approve the merge request if everything is in order.


### Merging with target branch

Before merging with the target branch, all merge conflicts are to be resolved locally and approval from the reviewer need to have been granted. As a general practice upon merge, the source branch should be closed. Exercise your own judgement on whether the source branch should be kept or deleted.