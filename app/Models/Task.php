<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    protected $fillable = ['title', 'description', 'assigned_to', 'assigned_by', 'due_date', 'status'];

    public function assignee()
    {
        return $this->belongsTo(Employee::class, 'assigned_to');
    }
    public function assigner()
    {
        return $this->belongsTo(Employee::class, 'assigned_by');
    }
}

