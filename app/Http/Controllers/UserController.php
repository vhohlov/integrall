<?php
 
namespace App\Http\Controllers;
 
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;


class UserController extends Controller
{
    /**
     * Show a list of all of the application's users.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    { 
        
       $users = DB::select('select * from app_users');
       var_dump($users);
        try {
            $redis = Redis::set('plm', '1234');
            var_dump(Redis::get('plm'));
        } catch (\Exception $e) {
            $isReady = false;
        }
    }
}