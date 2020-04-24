----------------------
--Author:brent
--DateTime:2020-04-23 20:08:20
--Describe:HeapTimer
-----------------------
local HeapTimer = {
    uniqueId = 0,
    runtime = 0,
    taskList = {}, 
}
cc.exports.HeapTimer = HeapTimer
local this = HeapTimer

function HeapTimer.Update(runtime)
    this.runtime = runtime
    HeapTimer.Check()
end

function HeapTimer.AddTimeTask(delay, func, interval, count)
    HeapTimer.uniqueId = HeapTimer.uniqueId + 1
    local newTask = {
        id = HeapTimer.uniqueId,
        expires = HeapTimer.runtime + delay,
        func = func,
        interval = interval,
        count = count
    }
    HeapTimer.PercolateUp(newTask)
    return HeapTimer.uniqueId
end
function HeapTimer.RemoveTimeTask(id)
    local hole = HeapTimer.GetHoleById(id)
    if hole ~= 0 then
        HeapTimer.PercolateDown(hole)
    else
        print('不存在的hole')
    end
end
function HeapTimer.ReplaceTimeTask(id, func)
    local hole = HeapTimer.GetHoleById(id)
    if hole ~= 0 then
        this.taskList[hole].func = func
    else
        print('不存在的hole')
    end
end

function HeapTimer.RemoveAllTimeTask(...)
    this.taskList = {}
    this.uniqueId = 0
end

--走检测的逻辑  只是不执行回调
--用于断线重连
function HeapTimer.CleanExpiredTask()
    local fastTask = this.taskList[1]
    if fastTask ~= nil then
        if fastTask.expires <= this.runtime then
            HeapTimer.PercolateDown()
            if fastTask.count and fastTask ~= 1 then
                if fastTask.count > 0 then
                    fastTask.count = fastTask.count - 1
                end
                fastTask.expires = HeapTimer.runtime + fastTask.interval
                HeapTimer.PercolateUp(fastTask)
            end
            HeapTimer.Check()
        end
    end
end

function HeapTimer.Check()
    local fastTask = this.taskList[1]
    if fastTask ~= nil then
        if fastTask.expires <= this.runtime then
            fastTask.func()
            HeapTimer.PercolateDown()
            if fastTask.count and fastTask.count ~= 1 then
                if fastTask.count > 0 then
                    fastTask.count = fastTask.count - 1
                   -- print(fastTask.count)
                end
                fastTask.expires = HeapTimer.runtime + fastTask.interval
                HeapTimer.PercolateUp(fastTask)
            end
            HeapTimer.Check()
        end
    end
end
function HeapTimer.GetHoleById(id)
    local idx = 0
    for k, v in pairs(this.taskList) do
        if v.id == id then
            idx = k
        end
    end
    return idx
end


function HeapTimer.PercolateUp(task)
    local hole = #this.taskList + 1  --计算添加的位置
    this.taskList[hole] = task
    local h = math.floor(math.log(hole, 2)) + 1    --完全二叉堆高度

    for i = 1, h - 1 do
        local parentHole = math.floor(hole / 2)
        if task.expires < this.taskList[parentHole].expires then
            this.taskList[hole] = this.taskList[parentHole]
            hole = parentHole
        else
            break
        end

    end
    this.taskList[hole] = task
end

function HeapTimer.PercolateDown(hole)
    if not hole then
        hole = 1
    end
    if #this.taskList < hole then
        --print('不存在的hole')
        return
    end

    if #this.taskList <= 2 or #this.taskList ==hole then
        table.remove(this.taskList, hole)
        return
    end

    this.taskList[hole] = this.taskList[#this.taskList]
    table.remove(this.taskList)

    local task = this.taskList[hole]
    local h = math.floor(math.log(#this.taskList, 2)) + 1 
    for i = 1, h - 1 do
        local compareHole = hole * 2
        local left = this.taskList[compareHole]
        local right = this.taskList[compareHole + 1]

        if right and right.expires < left.expires then
            --如果存在右节点 找到子节点中最小的 比较
            compareHole = compareHole + 1
        end

        if task.expires > this.taskList[compareHole].expires then
            this.taskList[hole] = this.taskList[compareHole]
            hole = compareHole
        end
    end
    this.taskList[hole] = task
end
return HeapTimer