

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Trouble</h1>

<!-- topic: Troubleshooting -->

<div class="text">

<p>
Troubleshooting
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#overview">OVERVIEW</a></li>
	<li><a href="#questions_and_answers">QUESTIONS AND ANSWERS</a></li>
	<ul>

		<li><a href="#the_daemon_does_not_start__or_immidiately_stops_without_any_message">The daemon does not start, or immidiately stops without any message</a></li>
		<li><a href="#the_daemon_complains_about_missing_mail_templates_on_startup">The daemon complains about missing mail templates on startup?</a></li>
		<li><a href="#i_get_a_message_about_bad_protocol__tcp">I get a message about ``bad protocol: tcp''</a></li>
	</ul>

	<li><a href="#author">AUTHOR</a></li>
	<li><a href="#contact">CONTACT</a></li>
</ul>
</div>


<p>Last update: 2005-06-22</p>

</div>



<h2><a name="overview">OVERVIEW</a></h2>

<div class="text">

<p>This document provides you with help for certain troubling moments that
are often experienced, but have (usually :) a simple solution.</p>



</div>

<h2><a name="questions_and_answers">QUESTIONS AND ANSWERS</a></h2>

<div class="text">



</div>

<h3><a name="the_daemon_does_not_start__or_immidiately_stops_without_any_message">The daemon does not start, or immidiately stops without any message</a></h3>

<div class="text">

<p>Answer:</p>

<ul>
<li>Run the daemon dicopd in the foreground, to see possible error messages.



<li>Look into logs/error.log and logs/proxy.log for error messages.



<li>Check that all files in <code>logs/</code> are writeable by the user/group you want the
daemon to run under. F.i. running it under user=dicop, group=dicop means
that <code>logs/</code>, <code>logs/error.log</code> and <code>logs/proxy.log</code> must be writable by 
the user <code>dicop</code>.

</ul>



</div>

<h3><a name="the_daemon_complains_about_missing_mail_templates_on_startup">The daemon complains about missing mail templates on startup?</a></h3>

<div class="text">

<p>Answer:</p>

<p>Make sure you have:</p>

<pre>
        mailtxt_dir = mail</pre>

<p>in your config file (and not <code>tpl/mail</code>). The prefix will be automatically
added from whatever your <code>tpl_dir</code> setting in the server config is.</p>

<p>Also, did you remember to rename the sample mail text files in that
directory by removing the <code>.sample</code> prefix?</p>



</div>

<h3><a name="i_get_a_message_about_bad_protocol__tcp">I get a message about ``bad protocol: tcp''</a></h3>

<div class="text">

<p>Answer:</p>

<p>This is message might appear as an error message at a client when it
connects to the proxy.</p>

<p>You are likely running Dicop-Proxy in a chroot environment and the
file <code>/etc/protocols</code> is not available in the chroot.</p>

<p>To solve this, create a directory <code>etc/</code> in your Dicop-Proxy directory
and copy the file <code>/etc/protocols</code> to it:</p>

<pre>
        cd /dicop-proxy/                # or wherever you unpacked the proxy
        mkdir etc
        cp /etc/protocols etc/</pre>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(C) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2005.</p>

<p>For licensing information please refer to the LICENSE file.</p>



</div>

<h2><a name="contact">CONTACT</a></h2>

<div class="text">
<pre>
        Address: BSI
                 Referat I2.3
                 Godesberger Alle 185-189
                 Bonn
                 53175
                 Germany
        email:   dicop@bsi.bund.de              (for public key see dicop.asc)
        www:     <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a></pre>



</div>


