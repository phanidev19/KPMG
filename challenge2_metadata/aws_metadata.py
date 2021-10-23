import sys

try:
    #Assigning arguement length to a variable
    a=len(sys.argv)-1

    print ("Number of arguments passed are","a")
    #Checking number of arguments are 2 or not
    if(a != 2): sys.exit("Invalid Arguments count passed")

    #print the meta data of a instance-id passed
    "aws ec2 --region sys.argv[1] describe-instances --instance-id sys.argv[2]"
    
except Exception as e: 
    print(e)





