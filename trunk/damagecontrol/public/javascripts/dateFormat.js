/*
   http://www.shoestringcms.com/personal/codelib/JavaScript/DemoDate.html

   dateFormat.js - Format a date to a user-defined string formats.
   Written by John Brooking, March 2001
   See DemoDate.htm for a demo of use.

   This program is released into the public domain. You are prohibited
   from selling it, and please include the existing revision history
   with any modifications you make, plus add your own. You are
   encouraged to share any modifications with me and others, and to
   report problems to me, at http://www.pobox.com/~JohnBrook.

   $Log3: F:\QVCS\Code Library\JavaScript\dateFormat.kt $

     A JavaScript routine to format dates to a variety of strings.

   Revision 1.4  by: John Brooking  Rev date: Thu Oct 03 08:18:00 2002
      Fixed bug in ordinals: All teens should get "th", not standard
      rules. (This was not really checked into QVCS, because my
      personal library is not functional currently. I'm just faking
      this entry.)

   Revision 1.3  by: John Brooking  Rev date: Fri Aug 31 16:40:00 2001
     Fixed bug in "quarter" equations.

   Revision 1.2  by: John Brooking  Rev date: Sat Apr 21 07:55:24 2001
     Fixed bug in %h% and %hh% formats (show hour as number 1-12) due to
     JavaScript handling of negative numbers. Midnight was being printed as
     "0" rather than "12". Thanks to Michael Ennis for reporting this.

   Revision 1.1  by: John Brooking  Rev date: Thu Mar 15 22:55:24 2001
     Added new formats %dth% and %ddth%, and added more verbosity about
     public domain use at the top.

   $Endlog$

*/


Date.prototype.format = function(fmt) {
   return dateFormat(fmt, this);
}


ESCAPE_CHR = "%";
ERR_UNCLOSED = "Error: Format string not terminated!";
ERR_UNKNOWN = "Error: Unknown format string!";

function isLeapYear(y)
{
   return (( y % 100 == 0 ) ? (y % 400 == 0) : (y % 4 == 0));
}

function dayOfYear(theDate)
{
   var monthlens = new Array(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
   var yearDay = 0

   // Total days in months prior to this one
   for( var mon = 0; mon < theDate.getMonth(); ++mon )
      yearDay += monthlens[mon];

   // Add one if March or later of a leap year
   if( isLeapYear(theDate.getFullYear()) && theDate.getMonth() >= 2 )
      ++yearDay;

   // Add days of current month
   yearDay += theDate.getDate();

   return yearDay;
}

function padnum2(n)
{
   return (n < 10) ? "0" + n : "" + n;
}

function dateFormat(fmt, theDate)
{
   var fmtIndex = 0, fmtLen = fmt.length;
   var c, thisFmt, mon, yearDay;
   var weekdays = new Array("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" );
   var monthnames = new Array("January", "February", "March", "April",
                              "May", "June", "July", "August", "September",
                              "October", "November", "December");
   var result = "";

   // If date parameter passed not an object, return blank.
   if( typeof(theDate) != "object" )
      return "";
   // This is almost the extent of our real sophisticated error checking!

   // Loop over each character in format string
   while( fmtIndex < fmtLen )
   {
      c = fmt.substr( fmtIndex, 1);

      // If it is a leading escape character,
      if( c == ESCAPE_CHR )
      {
         thisFmt = "";
         if( ++fmtIndex == fmtLen )
            return ERR_UNCLOSED;

         // Build up the format string
         while(( c = fmt.substr( fmtIndex, 1)) != ESCAPE_CHR )
         {
            thisFmt += c;
            if( ++fmtIndex == fmtLen )
               return ERR_UNCLOSED;
         }

         // Now just take the specified action!
         // (Yes, a switch statement would be more appropriate here, but
         // since that is a later addition to JS, I'm avoiding it here to
         // be as compatible as possible.)

         if( thisFmt == "d" )             // Day of month w/o leading 0
            result += theDate.getDate();

         else if (thisFmt == "dd" )       // Day of month with leading 0
            result += padnum2(theDate.getDate());

         else if (thisFmt == "ddd" )      // Day of week abbreviated
            result += weekdays[theDate.getDay()].substr(0,3);

         else if (thisFmt == "dddd" )     // Day of week full
            result += weekdays[theDate.getDay()];

         else if (thisFmt == "dth" )      // Day of month as ordinal w/o leading 0
         {
            var d = theDate.getDate();
            result += d;
            if( d > 10 && d < 20 ) {   // teens all get "th"
               result += "th";
            }
            else {                     // else, normal rules apply
               switch (d % 10) {
                  case 1: result += "st"; break;
                  case 2: result += "nd"; break;
                  case 3: result += "rd"; break;
                  default: result += "th"; break;
               }
            }
            /*
            if(( d % 10) == 1 )
               result += "st";
            else if(( d % 10) == 2 )
               result += "nd";
            else if(( d % 10) == 3 )
               result += "rd";
            else
               result += "th";
            */
         }

         else if (thisFmt == "ddth" )      // Day of month as ordinal with leading 0
         {
            var d = theDate.getDate();
            result += padnum2(d);
            if( d > 10 && d < 20 ) {   // teens all get "th"
               result += "th";
            }
            else {                     // else, normal rules apply
               switch (d % 10) {
                  case 1: result += "st"; break;
                  case 2: result += "nd"; break;
                  case 3: result += "rd"; break;
                  default: result += "th"; break;
               }
            }
            /*
            if(( d % 10) == 1 )
               result += "st";
            else if(( d % 10) == 2 )
               result += "nd";
            else if(( d % 10) == 3 )
               result += "rd";
            else
               result += "th";
            */
         }

         else if( thisFmt == "w" )        // Day of week as a number (0=Sun)
            result += theDate.getDay();

         else if( thisFmt == "ww" )       // Week of the year
            result += parseInt(dayOfYear(theDate)/7, 10) + 1;

         else if( thisFmt == "m" )        // Month number w/o leading 0
            result += theDate.getMonth() + 1;

         else if (thisFmt == "mm" )       // Month number with leading 0
            result += padnum2(theDate.getMonth() + 1);

         else if (thisFmt == "mmm" )      // Month name abbreviated
            result += monthnames[theDate.getMonth()].substr(0,3);

         else if (thisFmt == "mmmm" )     // Month name full
            result += monthnames[theDate.getMonth()];

         else if (thisFmt == "q" )        // Quarter of year as number
            result += parseInt(theDate.getMonth()/3) + 1;

         else if (thisFmt == "qq" )       // Quarter of year as ordinal
         {
            var q = parseInt(theDate.getMonth()/3);
            if( q == 0 )
               result += "1st";
            else if( q == 1 )
               result += "2nd";
            else if( q == 2 )
               result += "3rd";
            else if( q == 3 )
               result += "4th";
         }

         else if( thisFmt == "y" )        // Day of the year as number
            result += dayOfYear(theDate);

         else if( thisFmt == "yy" )       // Year as two digits
            result += ("" + theDate.getFullYear()).substr(2,2);

         else if( thisFmt == "yyyy" )     // Year as four digits
            result += theDate.getFullYear();

         else if( thisFmt == "h" )        // Hour (1-12) w/o leading 0
            result += ((theDate.getHours() + 12 - 1) % 12) + 1;

         else if (thisFmt == "hh" )       // Hour (1-12) with leading 0
            result += padnum2(((theDate.getHours() + 12 - 1) % 12) + 1);

         else if( thisFmt == "h24" )      // Hour (0-23) w/o leading 0
            result += theDate.getHours();

         else if (thisFmt == "hh24" )     // Hour (0-23) with leading 0
            result += padnum2(theDate.getHours());

         else if( thisFmt == "n" )        // Minute w/o leading 0
            result += theDate.getMinutes();

         else if (thisFmt == "nn" )       // Minute with leading 0
            result += padnum2(theDate.getMinutes());

         else if( thisFmt == "s" )        // Seconds w/o leading 0
            result += theDate.getSeconds();

         else if ( thisFmt == "ss" )      // Seconds with leading 0
            result += padnum2(theDate.getSeconds());

         else if ( thisFmt == "AM/PM" )   // AM/PM capitalized
            result += theDate.getHours() < 12 ? "AM" : "PM";

         else if ( thisFmt == "am/pm" )   // am/pm lowercase
            result += theDate.getHours() < 12 ? "am" : "pm";

         else if ( thisFmt == "A/P" )     // A/P capitalized
            result += theDate.getHours() < 12 ? "A" : "P";

         else if ( thisFmt == "a/p" )     // a/p lowercase
            result += theDate.getHours() < 12 ? "a" : "p";

         else if ( thisFmt == "tz")       // Timezone as hours behind Greenwich
            result += theDate.getTimezoneOffset();

         else if ( thisFmt == "tzn")      // Timezone as name
         {
            mon = "" + theDate;
            result += mon.substr(20, mon.length -  25);
         }

         else
            return ERR_UNKNOWN;
      }
      else
         result += c;

      ++fmtIndex;
   }  // while

   return result;
}
