<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Campaign extends Model {
  protected $fillable=['name','start_date','end_date','budget','objective'];
  public function customers(){return $this->belongsToMany(Customer::class,'campaign_participations');}
}
