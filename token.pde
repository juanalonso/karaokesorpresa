class Token {

  String palabra, palabraSustituta;
  int silabas;
  //boolean sustituir;
  int tipoPalabra;
  String tagInfo;


  Token(String _palabra, int _silabas, String _tagInfo) {

    this.palabra= _palabra;
    this.silabas =_silabas;
    this.tagInfo = _tagInfo;

    this.palabraSustituta = _palabra;

    tipoPalabra = SINTAXIS.FINAL;
    if (_tagInfo.indexOf("nombre")==0) {
      tipoPalabra = SINTAXIS.SUSTANTIVOS;
    } else if (_tagInfo.indexOf("adjetivo")==0) {
      tipoPalabra = SINTAXIS.ADJETIVOS;
    } else if (_tagInfo.indexOf("verbo, infinitivo")==0) {
      tipoPalabra = SINTAXIS.INFINITIVOS;
    } /*else if (_tagInfo.indexOf("adverbio")==0) {
      tipoPalabra = SINTAXIS.ADVERBIOS;
    }*/
  }


  String toString() {
    String toString = palabra;
    toString += " <s:" + silabas + ", " +  obtenerTipoPalabra() + ">";
    toString += " " + palabraSustituta;
    return toString;
  }


  String obtenerTipoPalabra() {

    String tipo = "otro";

    if (tipoPalabra==SINTAXIS.SUSTANTIVOS) {
      tipo = "sust";
    } else if (tipoPalabra==SINTAXIS.ADJETIVOS) {
      tipo = "adje";
    } else if (tipoPalabra==SINTAXIS.INFINITIVOS) {
      tipo = "infi";
    } else if (tipoPalabra==SINTAXIS.ADVERBIOS) {
      tipo = "adve";
    }
    return tipo;
  }


  @Override
    public boolean equals(Object obj) {
    if (obj instanceof Token) {
      Token t = (Token)obj;
      return palabra.equals(t.palabra) && tipoPalabra == t.tipoPalabra;
    }
    return false;
  }

  
  void asignarSustituta(String sustituta) {
    
    //println(palabra + "=" + sustituta);
    
    if (palabra.substring(0,1).equals(palabra.substring(0,1).toUpperCase())){
      sustituta = sustituta.substring(0,1).toUpperCase() + sustituta.substring(1);
    }
    
    palabraSustituta = sustituta;
    
  }

  //  String obtenerSustituta() {
  //    return sustituir ? palabraSustituta : palabra;
  //  }
}
