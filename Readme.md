# Rest Server
A stub server facilitate testing.

## How to use it?

    cd rest-server
    ruby app.rb

Then the server is running at port 3000

You can send http request to register resources.
###  register resource _users_ 

    POST http://localhost:3000/_  resource:users

### unregister resource _users_
    
    DELETE http://localhost:3000/_/users

### list all registered resources

    GET http://localhost:3000/_
    
    ["users"]

You can also send http request to do CRUD on registered resources. Suppose resource _users_ is registered.
### add user
    POST http://localhost:3000/users content:{"name":"zhangsan", "age":21}
    UUID
### update user
    PUT http://localhost:3000/users/UUID content:{"name":"zhangsan", "age":22}
### delete user
    DELETE http://localhost:3000/users/UUID
### list users
    GET http://localhost:3000/users

    [{"name":"zhangsan", "age":21}]

### show user
    GET http://localhost:3000/users/UUID

    {"name":"zhangsan", "age":21}


## Todos
- Add rake task to specify server port from command line
- Read content directly from request form when create or update user

