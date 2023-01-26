1. Install dependencies:

   ```
   % pip install psycopg2-binary
   % pip install -r requirements.txt
   ```
   
2. create secret phrase, and make it visible to the application:

    ```
    % cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:]' | head -c 128 > .secret
    % export AUTH_SERVER_SECRET_PATH=$(pwd)/.secret
    ```
    
3. provide a Postgres database url and create application db:

    ```
    % export POSTGRES_URL=postgresql://postgres@localhost/auth_server
    % python database/migrations/0001_initial.py
    password: 
    connect to postgresql://postgres@localhost/auth_server
    create database
    database created
    % python database/migrations/0002_initial_model.py 
    password: 
    connect to postgresql://postgres@localhost/auth_server
    create table users
    % 
    ```

Now you can create user with `tools/create_user.py` script:


    ```
    % python tools/create_user.py
    email(required):test@domain.example
    last name:
    first name:
    is administrator(y/N):
    password:
    db password:
    connect to postgresql://postgres@localhost/auth_server
    %
    ```
    
Or generate token for this user with `tools/generate_token.py`:


    ```
    % python tools/generate_token.py 
    email(required):test@domain.example
    db password:
    connect to postgresql://postgres@localhost/auth_server
    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjcwNTQzNTQuMTAyOTc5LCJuYmYiOjE2NjcwNTQyMzQuMTAyOTk0LCJhdWQiOiJ1cm46dXNlciIsImVtYWlsIjoidGVzdEBkb21haW4uZXhhbXBsZSJ9.dvR4A6L23MqLwKHWuS9vBfO-DbHd_reExQCJben6k0E
    % 
    ```
