<?php
namespace Wukka\DB;

/*
* This interface describes some of the methods, but it is more of a contract for the object to
* behave like the Wukka\DB object. Study the the Wukka\DB::execute( $query ) method.
* returns a standardized result object which can be used the same way regardless of whether or
* not the core is PDO or Mysqli.
*/

interface ExtendedIface extends Iface {
    
    /**
    * grab the object passed into the constructor.
    */
    public function core();
    
   /**
    * get the last error message generated by the db.
    */
    public function error();
    
    /**
    * get the last error code generated by the db.
    */
    public function errorcode();
}

// EOC
