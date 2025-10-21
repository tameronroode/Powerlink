<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Employee extends Model
{
    protected $table = 'employees';         // matches your migration
    protected $primaryKey = 'employee_id';  // UUID PK name
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['first_name', 'last_name', 'email', 'phone_number', 'role', 'hire_date'];
}
