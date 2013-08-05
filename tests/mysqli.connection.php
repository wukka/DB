<?php

return @ new \MySQLi( 
                '127.0.0.1', 
                $user = ini_get('mysqli.default_user'), 
                $pass = ini_get('mysqli.default_pw'), 
                'test', 
                ini_get('mysqli.default_port'));