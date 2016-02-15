# -*- coding: utf-8 -*-
#
# mercurial_keyring: save passwords in password database
#
# Copyright (c) 2009 Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# See README.txt for more details.

''' securely save HTTP and SMTP authentication details
mercurial_keyring is a Mercurial extension used to securely save
HTTP and SMTP authentication passwords in password databases (Gnome
Keyring, KDE KWallet, OSXKeyChain, specific solutions for Win32 and
command line). This extension uses and wraps services of the keyring
library.
'''

from mercurial import util
from mercurial.i18n import _
try:
    from mercurial.url import passwordmgr
except:
    from mercurial.httprepo import passwordmgr
from mercurial import mail
from urllib2 import AbstractBasicAuthHandler, AbstractDigestAuthHandler

# mercurial.demandimport incompatibility workaround.
# various keyring backends fail as they can't properly import helper
# modules (as demandimport modifies python import behaviour).
# If you get import errors with demandimport in backtrace, try
# guessing what to block and extending the list below.
from mercurial import demandimport
for blocked_module in [
    "gobject._gobject",
    "configparser",
    "json",
    "abc",
    "io",
    "keyring",
    "gdata.docs.service",
    "gdata.service",
    "types",
    "atom.http",
    "atom.http_interface",
    "atom.service",
    "atom.token_store",
    "ctypes",
    "secretstorage.exceptions",
    "fs.opener",
    ]:
    if blocked_module not in demandimport.ignore:
        demandimport.ignore.append(blocked_module)

# Temporarily disable demandimport to make the need of extending
# the list above less likely.
if __import__ == demandimport._import:
    demandimport.disable()
    try:
        import keyring
    finally:
        demandimport.enable()
else:
    import keyring

from urlparse import urlparse
import urllib2
import smtplib, socket
import os

KEYRING_SERVICE = "Mercurial"

############################################################

def monkeypatch_method(cls,fname=None):
    def decorator(func):
        local_fname = fname
        if local_fname is None:
            local_fname = func.__name__
        setattr(func, "orig", getattr(cls, local_fname, None))
        setattr(cls, local_fname, func)
        return func
    return decorator

############################################################

class PasswordStore(object):
    """
    Helper object handling keyring usage (password save&restore,
    the way passwords are keyed in the keyring).
    """
    def __init__(self):
        self.cache = dict()
    def get_http_password(self, url, username):
        return keyring.get_password(KEYRING_SERVICE,
                                    self._format_http_key(url, username))
    def set_http_password(self, url, username, password):
        keyring.set_password(KEYRING_SERVICE,
                             self._format_http_key(url, username),
                             password)
    def clear_http_password(self, url, username):
        self.set_http_password(url, username, "")
    def _format_http_key(self, url, username):
        return "%s@@%s" % (username, url)
    def get_smtp_password(self, machine, port, username):
        return keyring.get_password(
            KEYRING_SERVICE,
            self._format_smtp_key(machine, port, username))
    def set_smtp_password(self, machine, port, username, password):
        keyring.set_password(
            KEYRING_SERVICE,
            self._format_smtp_key(machine, port, username),
            password)
    def clear_smtp_password(self, machine, port, username):
        self.set_smtp_password(machine, port, username, "")
    def _format_smtp_key(self, machine, port, username):
        return "%s@@%s:%s" % (username, machine, str(port))

password_store = PasswordStore()

############################################################

def _debug(ui, msg):
    ui.debug("[HgKeyring] " + msg + "\n")

def _debug_reply(ui, msg, url, user, pwd):
    _debug(ui, "%s. Url: %s, user: %s, passwd: %s" % (
            msg, url, user, pwd and '*' * len(pwd) or 'not set'))


############################################################

class HTTPPasswordHandler(object):
    """
    Actual implementation of password handling (user prompting,
    configuration file searching, keyring save&restore).

    Object of this class is bound as passwordmgr attribute.
    """
    def __init__(self):
        self.pwd_cache = {}
        self.last_reply = None

    def find_auth(self, pwmgr, realm, authuri, req):
        """
        Actual implementation of find_user_password - different
        ways of obtaining the username and password.
        """
        ui = pwmgr.ui

        # If we are called again just after identical previous
        # request, then the previously returned auth must have been
        # wrong. So we note this to force password prompt (and avoid
        # reusing bad password indifinitely).
        after_bad_auth = (self.last_reply \
                          and (self.last_reply['realm'] == realm) \
                          and (self.last_reply['authuri'] == authuri) \
                          and (self.last_reply['req'] == req))
        if after_bad_auth:
            _debug(ui, _("Working after bad authentication, cached passwords not used %s") % str(self.last_reply))

        # Strip arguments to get actual remote repository url.
        base_url = self.canonical_url(authuri)

        # Extracting possible username (or password)
        # stored directly in repository url
        user, pwd = urllib2.HTTPPasswordMgrWithDefaultRealm.find_user_password(
            pwmgr, realm, authuri)
        if user and pwd:
            _debug_reply(ui, _("Auth data found in repository URL"),
                         base_url, user, pwd)
            self.last_reply = dict(realm=realm,authuri=authuri,user=user,req=req)
            return user, pwd

        # Loading .hg/hgrc [auth] section contents. If prefix is given,
        # it will be used as a key to lookup password in the keyring.
        auth_user, pwd, prefix_url = self.load_hgrc_auth(ui, base_url, user)
        if prefix_url:
            keyring_url = prefix_url
        else:
            keyring_url = base_url
        _debug(ui, _("Keyring URL: %s") % keyring_url)

        # Checking the memory cache (there may be many http calls per command)
        cache_key = (realm, keyring_url)
        if not after_bad_auth:
            cached_auth = self.pwd_cache.get(cache_key)
            if cached_auth:
                user, pwd = cached_auth
                _debug_reply(ui, _("Cached auth data found"),
                             base_url, user, pwd)
                self.last_reply = dict(realm=realm,authuri=authuri,user=user,req=req)
                return user, pwd

        if auth_user:
            if user and (user != auth_user):
                raise util.Abort(_('mercurial_keyring: username for %s specified both in repository path (%s) and in .hg/hgrc/[auth] (%s). Please, leave only one of those' % (base_url, user, auth_user)))
            user = auth_user
            if pwd:
                self.pwd_cache[cache_key] = user, pwd
                _debug_reply(ui, _("Auth data set in .hg/hgrc"),
                             base_url, user, pwd)
                self.last_reply = dict(realm=realm,authuri=authuri,user=user,req=req)
                return user, pwd
            else:
                _debug(ui, _("Username found in .hg/hgrc: %s") % user)

        # Loading password from keyring.
        # Only if username is known (so we know the key) and we are
        # not after failure (so we don't reuse the bad password).
        if user and not after_bad_auth:
            _debug(ui, _("Looking for password for user %s and url %s") % (user, keyring_url))
            pwd = password_store.get_http_password(keyring_url, user)
            if pwd:
                self.pwd_cache[cache_key] = user, pwd
                _debug_reply(ui, _("Keyring password found"),
                             base_url, user, pwd)
                self.last_reply = dict(realm=realm,authuri=authuri,user=user,req=req)
                return user, pwd
            else:
                _debug(ui, _("Password not present in the keyring"))

        # Is the username permanently set?
        fixed_user = (user and True or False)

        # Last resort: interactive prompt
        if not ui.interactive():
            raise util.Abort(_('mercurial_keyring: http authorization required but program used in non-interactive mode'))

        if not fixed_user:
            ui.status(_("Username not specified in .hg/hgrc. Keyring will not be used.\n"))

        ui.write(_("http authorization required\n"))
        ui.status(_("realm: %s\n") % realm)
        if fixed_user:
            ui.write(_("user: %s (fixed in .hg/hgrc)\n" % user))
        else:
            user = ui.prompt(_("user:"), default=None)
        pwd = ui.getpass(_("password: "))

        if fixed_user:
            # Saving password to the keyring.
            # It is done only if username is permanently set.
            # Otherwise we won't be able to find the password so it
            # does not make much sense to preserve it
            _debug(ui, _("Saving password for %s to keyring") % user)
            password_store.set_http_password(keyring_url, user, pwd)

        # Saving password to the memory cache
        self.pwd_cache[cache_key] = user, pwd

        _debug_reply(ui, _("Manually entered password"),
                     base_url, user, pwd)
        self.last_reply = dict(realm=realm,authuri=authuri,user=user,req=req)
        return user, pwd

    def load_hgrc_auth(self, ui, base_url, user):
        """
        Loading [auth] section contents from local .hgrc

        Returns (username, password, prefix) tuple (every
        element can be None)
        """
        # Theoretically 3 lines below should do:

        #auth_token = self.readauthtoken(base_url)
        #if auth_token:
        #   user, pwd = auth.get('username'), auth.get('password')

        # Unfortunately they do not work, readauthtoken always return
        # None. Why? Because ui (self.ui of passwordmgr) describes the
        # *remote* repository, so does *not* contain any option from
        # local .hg/hgrc.

        # TODO: mercurial 1.4.2 is claimed to resolve this problem
        # (thanks to: http://hg.xavamedia.nl/mercurial/crew/rev/fb45c1e4396f)
        # so since this version workaround implemented below should
        # not be necessary. As it will take some time until people
        # migrate to >= 1.4.2, it would be best to implement
        # workaround conditionally.

        # Workaround: we recreate the repository object
        repo_root = ui.config("bundle", "mainreporoot")

        from mercurial.ui import ui as _ui
        local_ui = _ui(ui)
        if repo_root:
            local_ui.readconfig(os.path.join(repo_root, ".hg", "hgrc"))
        try:
            local_passwordmgr = passwordmgr(local_ui)
            auth_token = local_passwordmgr.readauthtoken(base_url)
        except AttributeError:
            try:
                # hg 1.8
                import mercurial.url
                readauthforuri = mercurial.url.readauthforuri
            except (ImportError, AttributeError):
                # hg 1.9
                import mercurial.httpconnection
                readauthforuri = mercurial.httpconnection.readauthforuri
            if readauthforuri.func_code.co_argcount == 3:
                # Since hg.0593e8f81c71
                res = readauthforuri(local_ui, base_url, user)
            else:
                res = readauthforuri(local_ui, base_url)
            if res:
                group, auth_token = res
            else:
                auth_token = None
        if auth_token:
            username = auth_token.get('username')
            password = auth_token.get('password')
            prefix = auth_token.get('prefix')
            shortest_url = self.shortest_url(base_url, prefix)
            return username, password, shortest_url

        return None, None, None

    def shortest_url(self, base_url, prefix):
        if not prefix or prefix == '*':
            return base_url
        scheme, hostpath = base_url.split('://', 1)
        p = prefix.split('://', 1)
        if len(p) > 1:
            prefix_host_path = p[1]
        else:
            prefix_host_path = prefix
        shortest_url = scheme + '://' + prefix_host_path
        return shortest_url

    def canonical_url(self, authuri):
        """
        Strips query params from url. Used to convert urls like
        https://repo.machine.com/repos/apps/module?pairs=0000000000000000000000000000000000000000-0000000000000000000000000000000000000000&cmd=between
        to
        https://repo.machine.com/repos/apps/module
        """
        parsed_url = urlparse(authuri)
        return "%s://%s%s" % (parsed_url.scheme, parsed_url.netloc,
                              parsed_url.path)

############################################################

@monkeypatch_method(passwordmgr)
def find_user_password(self, realm, authuri):
    """
    keyring-based implementation of username/password query
    for HTTP(S) connections

    Passwords are saved in gnome keyring, OSX/Chain or other platform
    specific storage and keyed by the repository url
    """
    # Extend object attributes
    if not hasattr(self, '_pwd_handler'):
        self._pwd_handler = HTTPPasswordHandler()

    if hasattr(self, '_http_req'):
        req = self._http_req
    else:
        req = None

    return self._pwd_handler.find_auth(self, realm, authuri, req)

@monkeypatch_method(AbstractBasicAuthHandler, "http_error_auth_reqed")
def basic_http_error_auth_reqed(self, authreq, host, req, headers):
    self.passwd._http_req = req
    try:
        return basic_http_error_auth_reqed.orig(self, authreq, host, req, headers)
    finally:
        self.passwd._http_req = None

@monkeypatch_method(AbstractDigestAuthHandler, "http_error_auth_reqed")
def digest_http_error_auth_reqed(self, authreq, host, req, headers):
    self.passwd._http_req = req
    try:
        return digest_http_error_auth_reqed.orig(self, authreq, host, req, headers)
    finally:
        self.passwd._http_req = None

############################################################

def try_smtp_login(ui, smtp_obj, username, password):
    """
    Attempts smtp login on smtp_obj (smtplib.SMTP) using username and
    password.

    Returns:
    - True if login succeeded
    - False if login failed due to the wrong credentials

    Throws Abort exception if login failed for any other reason.

    Immediately returns False if password is empty
    """
    if not password:
        return False
    try:
        ui.note(_('(authenticating to mail server as %s)\n') %
                 (username))
        smtp_obj.login(username, password)
        return True
    except smtplib.SMTPException, inst:
        if inst.smtp_code == 535:
            ui.status(_("SMTP login failed: %s\n\n") % inst.smtp_error)
            return False
        else:
            raise util.Abort(inst)

def keyring_supported_smtp(ui, username):
    """
    keyring-integrated replacement for mercurial.mail._smtp
    Used only when configuration file contains username, but
    does not contain the password.

    Most of the routine below is copied as-is from
    mercurial.mail._smtp. The only changed part is
    marked with #>>>>> and #<<<<< markers
    """
    local_hostname = ui.config('smtp', 'local_hostname')
    s = smtplib.SMTP(local_hostname=local_hostname)
    mailhost = ui.config('smtp', 'host')
    if not mailhost:
        raise util.Abort(_('no [smtp]host in hgrc - cannot send mail'))
    mailport = int(ui.config('smtp', 'port', 25))
    ui.note(_('sending mail: smtp host %s, port %s\n') %
            (mailhost, mailport))
    s.connect(host=mailhost, port=mailport)
    if ui.configbool('smtp', 'tls'):
        if not hasattr(socket, 'ssl'):
            raise util.Abort(_("can't use TLS: Python SSL support "
                               "not installed"))
        ui.note(_('(using tls)\n'))
        s.ehlo()
        s.starttls()
        s.ehlo()

    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    stored = password = password_store.get_smtp_password(
        mailhost, mailport, username)
    # No need to check whether password was found as try_smtp_login
    # just returns False if it is absent.
    while not try_smtp_login(ui, s, username, password):
        password = ui.getpass(_("Password for %s on %s:%d: ") % (username, mailhost, mailport))

    if stored != password:
        password_store.set_smtp_password(
            mailhost, mailport, username, password)
    #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    def send(sender, recipients, msg):
        try:
            return s.sendmail(sender, recipients, msg)
        except smtplib.SMTPRecipientsRefused, inst:
            recipients = [r[1] for r in inst.recipients.values()]
            raise util.Abort('\n' + '\n'.join(recipients))
        except smtplib.SMTPException, inst:
            raise util.Abort(inst)

    return send

############################################################

orig_smtp = mail._smtp

@monkeypatch_method(mail)
def _smtp(ui):
    """
    build an smtp connection and return a function to send email

    This is the monkeypatched version of _smtp(ui) function from
    mercurial/mail.py. It calls the original unless username
    without password is given in the configuration.
    """
    username = ui.config('smtp', 'username')
    password = ui.config('smtp', 'password')

    if username and not password:
        return keyring_supported_smtp(ui, username)
    else:
        return orig_smtp(ui)
