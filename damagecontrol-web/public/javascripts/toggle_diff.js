function popupCode( url ) {
  window.open(url, "Code", "resizable=yes,scrollbars=yes,toolbar=no,status=no,height=150,width=400")
}

function toggleCode( id ) {
  if ( document.getElementById )
    elem = document.getElementById( id );
  else if ( document.all )
    elem = eval( "document.all." + id );
  else
    return false;
  elemStyle = elem.style;
    
  if ( elemStyle.display != "block" ) {
    elemStyle.display = "block"
  } else {
    elemStyle.display = "none"
  }

  return true;
}
  
// Make codeblocks hidden by default
document.writeln( "<style type=\"text/css\">div.diff { display: none }</style>" )
  