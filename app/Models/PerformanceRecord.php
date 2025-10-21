<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PerformanceRecord extends Model
{
    protected $fillable = ['employee_id', 'period', 'task_completed', 'customer_satisfaction_score', 'notes'];
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
