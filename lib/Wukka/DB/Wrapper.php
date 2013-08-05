<?php

namespace Wukka\DB;

class Wrapper implements IFace {
    
    protected $core;
    
    public function __construct( Iface $core ){
        $this->core = $core;
    }
    
    public function start($auth = NULL){
        return $this->core->start($auth);
    }
    
    public function rollback($auth = NULL){
        return $this->core->rollback($auth );
    }
    
    public function commit($auth = NULL){
        return $this->core->commit($auth );
    }
    
    public function execute($query){
        $args = func_get_args();
        return call_user_func_array( array($this->core, 'execute'), $args );
    }
    
    public function prep($query){
        $args = func_get_args();
        array_shift($args);
        return $this->prep_args( $query, $args );
    }
    
    public function prep_args( $query, array $args ){
        return $this->core->prep_args( $query, $args );
    }
    
    public function isa( $name ){
        if( $this instanceof $name ) return TRUE;
        if( method_exists( $this->core, 'isa') ) return $this->core->isa( $name );
        return ( $this->core instanceof $name );
    }
    
    public function hash(){
        return $this->core->hash();
    }   
    
    public function __get( $k ){
        return $this->core->$k;
    }
    
    public function __set( $k, $v ){
        return $this->core->$k = $v;
    }
    
    public function __isset( $k ){
        return isset( $this->core->$k );
    }
    
    public function __call( $method, $args ){
        return call_user_func_array( array( $this->core, $method ), $args );
    }
    
    public function __toString(){
        return '{' . get_class( $this ) . '} ' . $this->core->__toString();
    }

}