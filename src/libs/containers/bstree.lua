local Node = {}

Node.__index = Node

function Node:new(data)
    self = {}
    
    self._data = data
    self.left = nil
    self.right = nil
    
    setmetatable(self, Node)
    return self
end

function Node:data()
    return self._data
end

local Tree = {}
package.loaded["Tree"] = Tree

Tree.__index = Tree

function Tree:new()
    self = {}
    self._root = nil
    
    setmetatable(self, Tree)
    return self
end

local function contains(node, data)
    if node:data() == data then
        return true
    elseif data < node:data() then
        
        if node.left ~= nil then
            return contains(node.left, data)
        end
    else
        if node.right ~= nil then
            return contains(node.right, data)
        end
    end
    
    return false
end

function Tree:contains(data)
    if self._root == nil then
        return false
    end
    
    return contains(self._root, data)
end

local function insert(node, data)
    if data >= node:data() then
        if node.right == nil then
            local nodeNew = Node:new(data)
            node.right = nodeNew
        else
            node.right = insert(node.right, data)         
        end
    else
        if node.left == nil then
            local nodeNew = Node:new(data)
            node.left = nodeNew
        else
            node.left = insert(node.left, data)
        end
    end

    return node
end

function Tree:insert(data)
    if self._root == nil then
        local node = Node:new(data)
        self._root = node
        return
    end
    
    self._root = insert(self._root, data)
end

local function remove(node, data)
    if data > node:data() then
        if node.right == nil then
            return node, nil
        else
            node.right = remove(node.right, data)
        end
    elseif data < node:data() then
        if node.left == nil then
            return node, nil
        else
            node.left = remove(node.left, data)
        end
    else
        if node.left == nil and node.right == nil then
            return nil, data
        elseif node.left == nil then
            node = node.right
        elseif node.right == nil then
            node = node.left
        else
            node._data = node.right:data()
            node.right, _ = remove(node.right, node:data())
        end
    end
    
    return node, data
end

function Tree:remove(data)
    if self._root == nil then
        return nil
    end
    
    self._root, popped = remove(self._root, data)

    return popped
end

return Tree