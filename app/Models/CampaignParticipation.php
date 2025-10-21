<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CampaignParticipation extends Model
{
    protected $fillable = ['campaign_id', 'customer_id', 'engagement_level'];
    public $timestamps = false;
}