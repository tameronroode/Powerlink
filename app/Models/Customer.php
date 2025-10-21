<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    protected $fillable = ['first_name', 'last_name', 'email', 'phone', 'address', 'customer_type'];

    public function interactions()
    {
        return $this->hasMany(Interaction::class);
    }
    public function serviceTickets()
    {
        return $this->hasMany(ServiceTicket::class);
    }
    public function leads()
    {
        return $this->hasMany(Lead::class);
    }
    public function campaigns()
    {
        return $this->belongsToMany(Campaign::class, 'campaign_participations');
    }
}

