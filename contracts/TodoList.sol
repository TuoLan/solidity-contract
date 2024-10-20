// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TodoList {
    struct todoList{
        string name;
        uint256 count;
    }

    mapping (address =>todoList[]) public userTodoList;

    function addTodo(string memory _name, uint256 _count) external {
        userTodoList[msg.sender].push(todoList({name: _name, count: _count}));
    }

    function deleteTodo (uint256 _i) external {
        require(_i<userTodoList[msg.sender].length, "out of index");
        for(uint256 i = _i; i < userTodoList[msg.sender].length-1; i++) {
            userTodoList[msg.sender][i] = userTodoList[msg.sender][i+1];
        }
        userTodoList[msg.sender].pop();
    }

    function getUserTodoList () external view returns(todoList[] memory)  {
        return userTodoList[msg.sender];
    }
}