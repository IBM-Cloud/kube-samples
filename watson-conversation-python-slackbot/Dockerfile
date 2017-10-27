FROM ubuntu:latest

# Install all dependencies
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
RUN apt-get install -y python python-dev python-distribute python-pip
RUN apt-get install -y libffi-dev libssl-dev libcurl3 curl --fix-missing
RUN apt-get upgrade -y

# Copy all of the files into the image
COPY . /

# Install the requirements plus a few extras to supress warnings
RUN pip install -r requirements.txt

# Run the application
CMD ["python", "/bot/driver.py"]
