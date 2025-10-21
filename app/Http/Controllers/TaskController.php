<?php

namespace App\Http\Controllers;
use App\Http\Requests\StoreTaskRequest;


use App\Models\Task;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function index()
    {
        return Task::with(['assignee', 'assigner'])->latest()->paginate(20);
    }

    public function store(StoreTaskRequest $req)
    {
        $t = Task::create($req->validated());
        return response()->json($t->load(['assignee', 'assigner']), 201);
    }

    public function show(Task $task)
    {
        return $task->load(['assignee', 'assigner']);
    }

    public function update(StoreTaskRequest $req, Task $task)
    {
        $task->update($req->validated());
        return $task->load(['assignee', 'assigner']);
    }

    public function destroy(Task $task)
    {
        $task->delete();
        return ['ok' => true];
    }
}

