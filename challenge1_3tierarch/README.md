## Setting up 3 tier environment

Below arch shows the flow of application and the AWS services used to access the application.

Users will hit the DNS hosted on AWS Route53 and the traffic routes to Cloud Front ( used to solve network latency and cache of static content) with the origin used as Application Loadbalancer which listes to the target group pointed to web servers.
Also, used Auto scaling group for Application servers mapped with an internal load balancer and using a EFS ( external File system mounted common for both EC2 machines of App server). Backend db is hosted as AWS RDS.

By configuring this we are hosting our application with High availablity , more secure way and cost-effective.



![image](https://user-images.githubusercontent.com/50552335/138575080-a03e5c8e-af01-46ad-993e-6e7ecacade01.png)
