<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Lead extends Model
{
    protected $fillable = ['customer_id', 'assigned_employee_id', 'source', 'lead_status', 'notes'];
    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }
    public function assignee()
    {
        return $this->belongsTo(Employee::class, 'assigned_employee_id');
    }
}