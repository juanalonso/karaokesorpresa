class Rimas {

  HashMap<Integer, StringList> rimas;

  Rimas() {
    this.rimas = new HashMap<Integer, StringList>();
  }


  void add(int numSilabas, String palabra) {

    rimas.putIfAbsent(numSilabas, new StringList());
    StringList rimasPorSilabas = rimas.get(numSilabas);
    rimasPorSilabas.append(palabra);
  }


  boolean isEmpty() {
    return rimas.isEmpty();
  }


  String toString(boolean mostrarSilabas) {

    String toString = "";

    for (Integer key : rimas.keySet()) {

      if (toString.length()>0) {
        toString += "\n";
      }    

      if (mostrarSilabas) {
        toString += key + ": ";
      }
      StringList rimasPorSilabas = rimas.get(key); 
      for (String palabra : rimasPorSilabas) {
        toString += palabra + " ";
      }
    }
    return toString;
  }

  String[] toArray() {
    return split(this.toString(false), '\n');
  }
}
