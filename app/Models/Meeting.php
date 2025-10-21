<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Meeting extends Model
{
    protected $fillable = ['title', 'date_time', 'organizer_id'];
    public function organizer()
    {
        return $this->belongsTo(Employee::class, 'organizer_id');
    }
    public function attendees()
    {
        return $this->belongsToMany(Employee::class, 'meeting_attendances');
    }
}
