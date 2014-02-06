<?php
/**
 * RoundCube antiBruteForce
 *
 * @version 2.0
 * @author Anderson J. de Souza
 * @url http://anderjs.blogspot.com
 */
class antiBruteForce extends rcube_plugin
{

	private $registers="logs/userlogins"; // arquivo de registro de tentativas
	private $attempts=2; // o numero de tentativas antes de bloquear o acesso;
	private $registeredAttemptsInTime=0; // variavel que mantem o numero de tentativas registradas dentro do tempo determinado
	private $time=86400; // tempo entre tentativas
	private $blockedTime=null; // mantem o tempo restante de bloqueio em segundos
        private $whiteList = array();

  function init()
  {
    $this->add_hook('startup', array($this, 'clearAuth'));
    $this->add_hook('template_object_loginform', array($this, 'blockMessage'));
    $this->add_hook('login_failed', array($this, 'logFail'));
    $this->add_texts('localization', true);
  }

  function blocked() {
    // faz contabilizacao caso nao haja bloqueio definido
    if ($this->blockedTime === null ) 
	$this->checkFails(); 
    return $this->blockedTime;
  }

  function clearAuth($args) {
    if ($this->blocked()) {
      $args['task']='login';
      $args['action']='';
     }
    return $args;
  }

  function ip2bin($x){
    preg_match_all("/[0-9]{1,3}/","$x",$a);
    $b=array_map("decbin",$a[0]);
    //    $c=@array_map("fill0",$b);
    $p2=array(8,8,8,8);
    $p3=array('0','0','0','0');
    $p4=array(STR_PAD_LEFT, STR_PAD_LEFT, STR_PAD_LEFT, STR_PAD_LEFT);
    $c=array_map("str_pad",$b,$p2,$p3,$p4);
    return ("$c[0]$c[1]$c[2]$c[3]");
  }

  /*
   * Avalia se o ip pertence a rede informada ou nao
   */
  function isInNet($net) {
    $net = trim($net);
    if ($net == null) return false; // se não foi definida rede retorna falso
    $ip=explode(",",$this->getTrackIP());
    $ip=trim($ip[0]);
    if ($net == $ip) return true; // se for o proprio ip retorna verdadeiro
    if (strpos($net,"/") > 1) {
      $subnet=explode('/',$net);
      $netip = $this->ip2bin($ip); // binario do ip
      $netnet = $this->ip2bin($subnet[0]); // binario da rede
      $ret=($netnet & $netip);
      return ($netnet === $ret);
    }
    return false;
  }

  function getTrackIP(){
	 $trackIP = getenv('REMOTE_ADDR');
	 if (getenv('HTTP_X_FORWARDED_FOR'))
		 $trackIP=getenv('HTTP_X_FORWARDED_FOR').','.$trackIP;
	 return $trackIP;
  }

  function checkFails() {
          // retorna antes de alterar valores se encontrar ip dentro de rede segura
          foreach ($this->whiteList as $net) if ( $this->isInNet($net)===true ) return 0;

	  $track=$this->getTrackIP(); // caminho utilizado do acesso ip e ips de proxys
	  $time=$this->time; // tempo entre tentativas
	  $attempts=0; // registra o numero de tentativas dentro do tempo definido
	  $now=time(); // tempo de agora para calculos
	  $wait=0; // tempo entre as tentativas, mantem o time da ultima tentativa invalida
	  $w1=0; // guarda o tempo da primeira tentativa dentro do tempo avaliado.

	  // le arquivo contabilizando as falhas de login dentro do tempo determinado
	  if (is_file($this->registers) && $fp=fopen($this->registers,'r')){
	  while ( $line=fgets($fp) ) {
		  if ( substr($line,0,strlen($track.":")) == $track.":" ) {
			  if ( ($wait = $now - substr($line,strlen($track.":"),10)) < $time ) {
				  if ($attempts == 0) $w1 = $wait;
				  $attempts++;
			  }

		  }
	  }
	  fclose($fp);
	  }

	// guarda valores para pesquisas futuras.
	if ($attempts >= $this->attempts) $this->blockedTime = ($time - $w1);
	$this->registeredAttemptsInTime = $attempts;
	return $attempts;
  }

  function blockMessage($args) {
    $ip=explode(",",$this->getTrackIP());
    $ip=trim($ip[0]);
    if ($this->blocked()) 
      $args['content']=$this->gettext('blocked')." ".$this->blocked()."<br />".$this->getTrackIP();
    // hack ypou: no message at all instead
    if ($this->blocked()) 
      $args['content']='';
    // oehack 
    return $args;
  }


  function logFail($args)
  {
    if ($this->blocked()) return; // caso ja esteja bloqueado nao precisa registrar

    $log_entry = 'FAILED login for ' .$args['user']. ' from ' .getenv('REMOTE_ADDR'); 
    $log_config = rcmail::get_instance()->config->get('log_driver');
    
    error_log($this->getTrackIP().':'.time().':'.$args['user'].":[".date('d-M-Y H:i:s O')."]:$log_entry:"."\n", 3, $this->registers);
    
  }

}

?>
