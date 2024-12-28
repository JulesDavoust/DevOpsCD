# Build and deploy our application

In this section, we will explore how we utilized Kubernetes, Docker, and Jenkins to implement a continuous build and deployment process.

First, we will discuss how we set up the testing for our Go application to ensure the [/whoami]() endpoint returns the expected value.

## Testing the Application in Go

You can find the code for our application in the [main.go](webapi/main.go) file and the API test in the [main_test.go](webapi/main_test.go) file.

The first step involved familiarizing ourselves with the Go programming language and understanding the existing code. This allowed us to modify the application and add our names, surnames, and class group to the [/whoami]() endpoint.

### Modification of Types

We modified the [main.go](webapi/main.go) file by adding new types and updating the `whoAmI()` and `request1()` functions.

Previously, there was only one type defined in the code:\
![alt text](/images_README/jenkins/image-bis.png)

We introduced two new types and removed the old one:\
![alt text](/images_README/jenkins/image.png)

The old type was removed because it no longer suited our requirements. By including our class and personal information, we needed to create a new type, `ClassInfo`, to store the class details and our personal information. To handle our personal data, we introduced a `Student` type to store first names and last names.

### Modification of Functions

To complete the updates in this file, we modified two functions: `whoAmI()` and `request1()`.

The original `whoAmI()` function looked like this:\
![alt text](/images_README/jenkins/image-1.png)

After introducing the new types, we updated the `whoAmI()` function accordingly:\
![alt text](/images_README/jenkins/image-2.png)

The main changes are reflected in the structure of the `who` variable, as we leveraged the newly created types.

Finally, we made a small adjustment to the `request1()` function by changing the API's port from 8080 to 9090, since port 8080 was already in use by Jenkins.\

![alt text](/images_README/jenkins/image-3.png) ![alt text](/images_README/jenkins/image-4.png)


## Configuration de Kubernetes et docker

## Jenkins Configuration

The final step of the build and deploy process was configuring Jenkins. Jenkins allows us to execute a pipeline that performs tasks such as building images, deploying the application in the development environment for testing, and then deploying it to production if the test passes.

Before creating the pipeline, we had to configure Jenkins to connect to our VM and use it as a slave. Additionally, we needed to enable Jenkins to access our GitHub repository and DockerHub (to push the images).

We started by installing the Jenkins image on our VM:
```sh
sudo docker run -d -p 8080:8080 -p 50000:50000 --name jenkins --restart unless-stopped jenkins/Jenkins:lts-jdk17
```

Next, we retrieved the Jenkins credentials to log in:
```sh
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Now, let's delve deeper into the specific steps we took to configure Jenkins.

### Plugin Installation

The first step we took was to install the following plugins (though sometimes they may already be installed):

- Git Plugin  
- Docker Pipeline  
- Credentials Plugin  

To install these plugins, we navigated to the following section:\
[Dashboard > Manage Jenkins > Plugins](http://localhost:8080/manage/pluginManager/available)

From there, we accessed the "Available Plugins" tab and searched for the plugins listed above.

### Credentials Configuration

Next, we configured the credentials we needed to successfully complete this project. This included the credentials for our GitHub repository, DockerHub, and VM.

#### GitHub Credentials

To configure the credential for our GitHub account, we first needed to generate an access token with specific permissions. For this, we navigated to:\
[Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)

We then generated a new classic token with the following permissions:\
![alt text](/images_README/jenkins/image-5.png)
![alt text](/images_README/jenkins/image-6.png)
![alt text](/images_README/jenkins/image-7.png)

Once the token was generated:\
![alt text](/images_README/jenkins/image-8.png)

We retrieved the token and created a credential in Jenkins under Global Credentials:\
[Dashboard > Manage Jenkins > Credentials > System > Global credentials (unrestricted)](http://localhost:8080/manage/credentials/store/system/domain/_/)

We added a new credential by selecting "Username and password":\
![alt text](/images_README/jenkins/image-9.png)

Next, we entered our GitHub username and the previously generated token:\
![alt text](/images_README/jenkins/image-10.png)

Finally, we clicked "Create," and our GitHub credential was successfully configured!\
![alt text](/images_README/jenkins/image-13.png)

#### DockerHub Credentials

To configure the credential for our DockerHub account, we also needed to generate an access token. For this, we navigated to:\
[Account settings > Personal access tokens > Generate new token](https://app.docker.com/settings/personal-access-tokens/create)

We then configured our token as follows:\
![alt text](/images_README/jenkins/image-11.png)

The token was generated, and we could confirm its creation:\
![alt text](/images_README/jenkins/image-12.png)

Finally, we navigated to Jenkins to configure our DockerHub credentials (in the same location as for GitHub):\
[Dashboard > Manage Jenkins > Credentials > System > Global credentials (unrestricted)](http://localhost:8080/manage/credentials/store/system/domain/_/)

The process is similar to the GitHub credential setup, but this time, we entered our DockerHub username and the token we just generated:\
![alt text](/images_README/jenkins/image-14.png)

We selected "Create," and our DockerHub credential was successfully configured!\
![alt text](/images_README/jenkins/image-15.png)

#### VM credentials

Why do we need to configure credentials for our VM? Simply because we will allow Jenkins to use our VM as a slave, meaning it will be utilized by Jenkins to execute pipeline actions.

To achieve this, we need to generate an RSA key pair on our VM. First, we will create a jenkins user, which will also create a jenkins directory, by executing the following commands:
```sh
sudo adduser jenkins
chown -R jenkins:jenkins /home/jenkins
chmod 700 /home/jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart docker
```
![alt text](/images_README/jenkins/image-18.png)
![alt text](/images_README/jenkins/image-bisbis.png)


Next, inside the jenkins directory, we will create a .ssh folder:\
![alt text](/images_README/jenkins/image-16.png)

This folder will hold our RSA key pair after its generation:
```sh
ssh-keygen -t rsa -b 2048 -C "jenkins-agent"
```
![alt text](/images_README/jenkins/image-19.png)\
As shown above, the keys have been successfully created.

We will then add the public key to an authorized_keys file using the following command:
```sh
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```
![alt text](/images_README/jenkins/image-42.png)

This step informs the VM that users with the corresponding private key are allowed to connect.

Finally, we will move the generated keys into the .ssh folder within the jenkins directory:
```sh
cp ~/.ssh/id_rsa /home/jenkins/.ssh/
cp ~/.ssh/id_rsa.pub /home/jenkins/.ssh/
cp ~/.ssh/authorized_keys /home/jenkins/.ssh/
```

This setup allows Jenkins to connect to our VM.

Next, we need to adjust the file and folder permissions by running these commands:
```sh
chmod 600 /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/id_rsa
chmod 644 /home/jenkins/.ssh/id_rsa.pub
chmod 700 /home/jenkins/.ssh
chown -R jenkins:jenkins /home/jenkins/.ssh
```
![alt text](/images_README/jenkins/image-21.png)\
These commands ensure proper configuration of the keys and prevent connectivity issues between Jenkins and the VM.

To complete the credential setup, we must edit the following file:
```sh
nano /etc/ssh/sshd_config
```
Modify the following line:\
![alt text](/images_README/jenkins/image-22.png)\
Replace no with yes.

And this line:\
![alt text](/images_README/jenkins/image-23.png)\
Replace yes with no.
After making these changes, restart the SSH service with the following command:
```sh
sudo systemctl restart ssh
```

Save the changes. Finally, we will copy the private RSA key:
```sh
cat /home/jenkins/.ssh/id_rsa
```
![alt text](/images_README/jenkins/image-24.png)

Next, navigate to the following location in Jenkins to configure the VM credentials:\
[Tableau de bord > Administrer jenkins > Identifiants > System > Identifiants globaux (illimité)](http://localhost:8080/manage/credentials/store/system/domain/_/)

This time, choose "SSH Username with private key":\
![alt text](/images_README/jenkins/image-25.png)

Enter an ID, description, and username:\
![alt text](/images_README/jenkins/image-34.png)

For "Username", make sure to enter the name of the user we created earlier, which in our case is "jenkins". Otherwise, the configuration will not work.

Finally, choose Enter directly for the "Private key" field and paste your private key:\
![alt text](/images_README/jenkins/image-27.png)

Click "Create", and you will see that the credentials have been successfully configured!\
![alt text](/images_README/jenkins/image-28.png)


All credentials are now properly set up:\
![alt text](/images_README/jenkins/image-29.png)

We can now proceed to create our Jenkins agent.

### Creating a Jenkins Agent

The Jenkins agent will use our VM to execute the actions defined in our pipeline.

Before setting up the agent in Jenkins, we needed to install OpenJDK 17 on our VM, as this is the version required by our Jenkins instance. This installation allows the agent to execute the necessary tasks:
```sh
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk -y
``` 

Next, to create our agent, navigate to the following section in Jenkins:\
[Tableau de bord > Administrer jenkins > Nœuds > New Node](http://localhost:8080/manage/computer/new)

The first step is to provide a name for our node:
![alt text](/images_README/jenkins/image-30.png)
Then, select "Permanent Agent" and click "Create."

Now, we need to configure a few essential parameters for our agent:\
![alt text](/images_README/jenkins/image-31.png)\
In the "Remote root directory" field, specify the path to the jenkins directory we created earlier on our VM.

Next, under "Launch method," choose the "Launch agent via SSH" option:\
![alt text](/images_README/jenkins/image-32.png)

Finally, configure the following options:\
![alt text](/images_README/jenkins/image-33.png)
- In the "Host" field, enter the IP address of your VM. Depending on your VM configuration (e.g., if you are using a graphical interface), you may be able to use "localhost" instead.
- In the "Credentials" field, select the credentials labeled jenkins that we previously created. These credentials will establish the connection between Jenkins and the VM.
- For "Host Key Verification Strategy," choose "Non verifying Verification Strategy" to avoid connectivity issues. Since this is not an enterprise context, it is acceptable to use this option. Finally, click "Save."
![alt text](/images_README/jenkins/image-35.png)

As shown above, the agent has successfully launched.

### Creating the Pipeline

After setting up the agent, we moved on to configuring the pipeline.

#### Configuration of the jenkins.build File
First, we created a [build jenkins](Jenkins.build). This file specifies the actions that Jenkins will execute during the pipeline.

Our file is divided into six parts, or "stages." Before defining the stages, we specified the agent that the pipeline should use: "vm-agent".

**Stage 1 :**
![alt text](/images_README/jenkins/image-36.png)
This stage clones the source code from our GitHub repository. It specifies the main branch, uses the github-credential for authentication, and fetches the repository from the provided URL. This step ensures the pipeline has access to the necessary files for subsequent stages.

**Stage 2 :**
![alt text](/images_README/jenkins/image-37.png)
In this stage, we build a Docker image for the webapi service. Jenkins navigates to the project-main/webapi directory and uses the Dockerfile located there to create the image named thedevgods/devopsproject:1. This step prepares the containerized image for future use.

**Stage 3 :**
![alt text](/images_README/jenkins/image-38.png)
This stage pushes the Docker image created in the previous step to a remote Docker registry. It uses the docker-credential for authentication. Once the image is pushed, it becomes available for other environments, such as Kubernetes clusters (which will be used in later stages), enabling future deployments.

**Stage 4 :**
![alt text](/images_README/jenkins/image-39.png)
This stage deploys the application to the development environment on Kubernetes. It first applies the [namespace-development.yml](/project-main/kubernetes/namespace-development.yml) file to configure the namespace, then uses the [webapi-deployment.yml](/project-main/kubernetes/webapi-deployment.yml) file to deploy the application. Finally, the `kubectl get pods -n development` command displays the status of the pods deployed in the development namespace, ensuring that the deployment was successful.

**Stage 5 :**
![alt text](/images_README/jenkins/image-40.png)
This stage verifies that the application deployed in the development environment is functioning correctly. It makes a curl request to the [/whoami](http://localhost:9090/whoami) endpoint of the deployed service and compares the response to an expected value defined in the script. If the response matches the expected value, the test succeeds with a validation message; otherwise, it raises an error and displays the actual response for debugging.

**Stage 6 :**
![alt text](/images_README/jenkins/image-41.png)
Finally, this stage deploys the application to the production environment, provided that all previous stages were successful. It applies the [namespace-production.yml](/project-main/kubernetes/namespace-production.yml) file to configure the production namespace and uses the [webapi-deployment.yml](/project-main/kubernetes/webapi-deployment.yml) file to deploy the application to production. The `kubectl get pods -n production` command then displays the status of the pods deployed in the production namespace to confirm that everything is functioning as expected.

#### Allow Jenkins to Use kubectl

Before configuring the Jenkins pipeline, we need to enable Jenkins to execute kubectl commands.\
To achieve this, the first step is to create a .kube directory in the Jenkins user's home directory. Then, we will copy the Kubernetes configuration file from the .kube directory of the main user to the Jenkins user's .kube directory. Finally, we will modify specific lines in the configuration file.\
Here are the commands to execute:
```sh
sudo mkdir -p /home/jenkins/.kube
sudo chown -R jenkins:jenkins /home/jenkins/.kube
sudo cp /home/<our user>/.kube/config /home/jenkins/.kube/config
sudo chown jenkins:jenkins /home/jenkins/.kube/config
sudo nano /home/jenkins/.kube/config
```
![alt text](image-130.png)
In the configuration file, we replaced the following lines:
```
client-certificate: /home/<our user>/.minikube/profiles/minikube/client.crt
client-key: /home/<our user>/.minikube/profiles/minikube/client.key
certificate-authority: /home/<our user>/.minikube/ca.crt
```
With these:
```
client-certificate: /home/jenkins/.minikube/profiles/minikube/client.crt
client-key: /home/jenkins/.minikube/profiles/minikube/client.key
certificate-authority: /home/jenkins/.minikube/ca.crt
```
![alt text](image-131.png)

Finally, we created a .minikube directory for the Jenkins user and copied specific files from the main user's .minikube directory into it. To do so, we executed these commands:
```sh
sudo mkdir -p /home/jenkins/.minikube/profiles/minikube
sudo cp /home/jules/.minikube/profiles/minikube/client.crt /home/jenkins/.minikube/profiles/minikube/
sudo cp /home/jules/.minikube/profiles/minikube/client.key /home/jenkins/.minikube/profiles/minikube/
sudo cp /home/jules/.minikube/ca.crt /home/jenkins/.minikube/
sudo chown -R jenkins:jenkins /home/jenkins/.minikube
```
![alt text](image-132.png)

We can now proceed with configuring the Jenkins pipeline.

#### Pipeline Configuration

Once the necessary preparations were completed, we proceeded to configure the pipeline in Jenkins. To do this, we navigated to the following section:\
[Tableau de bord > Tous > Nouveau Item ](http://localhost:8080/view/all/newJob)\
![alt text](/images_README/jenkins/image-44.png)
We provided a name for our pipeline, selected "Pipeline," and clicked "OK."

Next, we went directly to the "Pipeline" section and selected "Pipeline script from SCM":\
![alt text](/images_README/jenkins/image-45.png)

For the "SCM" type, we chose "Git":\
![alt text](/images_README/jenkins/image-46.png)
We entered the URL of our GitHub repository, which contains the application's source code and all the necessary configuration files. Additionally, we selected the credentials we had previously created for our GitHub repository, allowing Jenkins to access the source code in a private repository. This step is crucial for repositories that require authentication.

Finally, we specified the branch we wanted to target in the repository— in our case, "main":\
![alt text](/images_README/jenkins/image-48.png)
We also provided the path to our [jenkins.build](Jenkins.build) file.

After clicking "Save," we triggered a build to test if everything was working correctly.
![alt text](/images_README/jenkins/image-49.png)

### Verification

We can confirm that the pipeline executed successfully, as shown in the [status](/) :\
![alt text](/images_README/jenkins/image-133.png)

Or in the [Pipeline overview](/) :\
![alt text](/images_README/jenkins/image-134.png)

Additionally, we can verify the execution of all stages and view their output in the [Console Output](/):\
Nous pouvons voir que l'image a bien été build :
![alt text](/images_README/jenkins/image-135.png)\
De plus, nous l'avons sur notre VM aussi:
![alt text](/images_README/jenkins/image-143.png)

We can also observe that the DockerHub login was successful and the image was pushed correctly:
![alt text](/images_README/jenkins/image-136.png)
![alt text](/images_README/jenkins/image-137.png)

We can also see that the deployment of the API in the development environment was successful:
![alt text](/images_README/jenkins/image-138.png)\
This is also confirmed on our VM:
![alt text](/images_README/jenkins/image-141.png)

When checking the test step, we can see that the test was executed successfully:
![alt text](/images_README/jenkins/image-139.png)

Finally, we can confirm that the deployment in the production environment was successful, and overall, the pipeline executed as expected:
![alt text](/images_README/jenkins/image-140.png)\
Here is the production deployment on our VM:
![alt text](/images_README/jenkins/image-142.png)

Alternatively, you can check the [Pipeline Console](/), which might be clearer:\
![alt text](/images_README/jenkins/image-144.png)

Moreover, if we check our DockerHub repository, we can see the image of our API has been successfully uploaded:\
![alt text](/images_README/jenkins/image-145.png)

We can even access it and navigate directly to its endpoint in each environment:\
![alt text](/images_README/jenkins/image-146.png)

## Conclusion

In this section, we learned how to create Kubernetes files to deploy an application to different environments, such as development and production, by defining namespaces, deployments, and appropriate services. We also configured Jenkins to automate these deployments through a CI/CD pipeline, which manages the steps of building, testing, and deploying based on the results of a unit test.

This integration ensures continuous deployment while verifying that the application works correctly before promoting it to the production environment.
