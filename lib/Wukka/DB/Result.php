<?php
namespace Wukka\DB;

class Result {

    protected $_ = array();
    
    public function __construct( array $map ){
        $this->_ = $map;
    }
    
    public function affected(){
        if( ! isset( $this->_[ __FUNCTION__ ] ) ) return 0;
        return $this->_[ __FUNCTION__ ];
    }
    
    public function insertid(){
        if( ! isset( $this->_[ __FUNCTION__ ] ) ) return NULL;
        return $this->_[ __FUNCTION__ ];
    }
    
    public function free(){
        if( ! isset( $this->_[ __FUNCTION__ ] ) ) return;
        $f = $this->_[ __FUNCTION__ ];
        return $f();
    }
    
    public function fetch(){
        if( ! isset( $this->_[ __FUNCTION__ ] ) ) return FALSE;
        $f = $this->_[ __FUNCTION__ ];
        return $f();
    }
    
    public function all(){
        $rows = array();
        while( $row = $this->fetch() ) $rows[] = $row;
        return $rows;
    }
    
    public function __toString(){
        @ $res ='(Wukka\DB\Result object - ' . "\n" .
            '  [affected] => ' . $this->affected() . "\n" .
            '  [insertid] => ' . $this->insertId() . "\n" .
            ')';
        return $res;
    }
}