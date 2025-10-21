<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MeetingAttendance extends Model
{
    protected $fillable = ['meeting_id', 'employee_id', 'attendance_status'];
    public $timestamps = false;
}