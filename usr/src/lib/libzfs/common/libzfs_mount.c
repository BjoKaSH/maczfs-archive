/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 * Portions Copyright 2007 Apple Inc. All rights reserved.
 * Use is subject to license terms.
 */

#pragma ident	"%Z%%M%	%I%	%E% SMI"

/*
 * Routines to manage ZFS mounts.  We separate all the nasty routines that have
 * to deal with the OS.  The following functions are the main entry points --
 * they are used by mount and unmount and when changing a filesystem's
 * mountpoint.
 *
 * 	zfs_is_mounted()
 * 	zfs_mount()
 * 	zfs_unmount()
 * 	zfs_unmountall()
 *
 * This file also contains the functions used to manage sharing filesystems via
 * NFS and iSCSI:
 *
 * 	zfs_is_shared()
 * 	zfs_share()
 * 	zfs_unshare()
 *
 * 	zfs_is_shared_nfs()
 * 	zfs_share_nfs()
 * 	zfs_unshare_nfs()
 * 	zfs_unshareall_nfs()
 * 	zfs_is_shared_iscsi()
 * 	zfs_share_iscsi()
 * 	zfs_unshare_iscsi()
 *
 * The following functions are available for pool consumers, and will
 * mount/unmount and share/unshare all datasets within pool:
 *
 * 	zpool_enable_datasets()
 * 	zpool_disable_datasets()
 */

#include <dirent.h>
#ifndef __APPLE__
#include <dlfcn.h>
#endif
#include <errno.h>
#include <libgen.h>
#include <libintl.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <unistd.h>
#ifdef __APPLE__
#include <sys/param.h>
#include <sys/xattr.h>
#else
#include <zone.h>
#endif /*__APPLE__*/
#include <sys/mntent.h>
#include <sys/mnttab.h>
#ifdef __APPLE__
#include <maczfs/maczfs_mount.h>
#else
#include <sys/mount.h>
#endif /* __APPLE__ */
#include <sys/stat.h>

#include <libzfs.h>

#include "libzfs_impl.h"

#ifndef __APPLE__
#include <libshare.h>
#include <sys/systeminfo.h>
#endif

#define	MAXISALEN	257	/* based on sysinfo(2) man page */

#ifndef __APPLE__
static int (*iscsitgt_zfs_share)(const char *);
static int (*iscsitgt_zfs_unshare)(const char *);
static int (*iscsitgt_zfs_is_shared)(const char *);
static int (*iscsitgt_svc_online)();

#pragma init(zfs_iscsi_init)
static void
zfs_iscsi_init(void)
{
	void *libiscsitgt;

	if ((libiscsitgt = dlopen("/lib/libiscsitgt.so.1",
	    RTLD_LAZY | RTLD_GLOBAL)) == NULL ||
	    (iscsitgt_zfs_share = (int (*)(const char *))dlsym(libiscsitgt,
	    "iscsitgt_zfs_share")) == NULL ||
	    (iscsitgt_zfs_unshare = (int (*)(const char *))dlsym(libiscsitgt,
	    "iscsitgt_zfs_unshare")) == NULL ||
	    (iscsitgt_zfs_is_shared = (int (*)(const char *))dlsym(libiscsitgt,
	    "iscsitgt_zfs_is_shared")) == NULL ||
	    (iscsitgt_svc_online = (int (*)(const char *))dlsym(libiscsitgt,
	    "iscsitgt_svc_online")) == NULL) {
		iscsitgt_zfs_share = NULL;
		iscsitgt_zfs_unshare = NULL;
		iscsitgt_zfs_is_shared = NULL;
		iscsitgt_svc_online = NULL;
	}
}
#endif /* !__APPLE__ */

/*
 * Search the sharetab for the given mountpoint, returning true if it is found.
 */
static boolean_t
is_shared(libzfs_handle_t *hdl, const char *mountpoint)
{
	char buf[MAXPATHLEN], *tab;

	if (hdl->libzfs_sharetab == NULL)
		return (0);

	(void) fseek(hdl->libzfs_sharetab, 0, SEEK_SET);

	while (fgets(buf, sizeof (buf), hdl->libzfs_sharetab) != NULL) {

		/* the mountpoint is the first entry on each line */
		if ((tab = strchr(buf, '\t')) != NULL) {
			*tab = '\0';
			if (strcmp(buf, mountpoint) == 0)
				return (B_TRUE);
		}
	}

	return (B_FALSE);
}

#ifndef __APPLE__
/*
 * Returns true if the specified directory is empty.  If we can't open the
 * directory at all, return true so that the mount can fail with a more
 * informative error message.
 */
static boolean_t
dir_is_empty(const char *dirname)
{
	DIR *dirp;
	struct dirent64 *dp;

	if ((dirp = opendir(dirname)) == NULL)
		return (B_TRUE);

	while ((dp = readdir64(dirp)) != NULL) {

		if (strcmp(dp->d_name, ".") == 0 ||
		    strcmp(dp->d_name, "..") == 0)
			continue;

		(void) closedir(dirp);
		return (B_FALSE);
	}

	(void) closedir(dirp);
	return (B_TRUE);
}
#endif /*!__APPLE__*/

/*
 * Checks to see if the mount is active.  If the filesystem is mounted, we fill
 * in 'where' with the current mountpoint, and return 1.  Otherwise, we return
 * 0.
 */
boolean_t
is_mounted(libzfs_handle_t *zfs_hdl, const char *special, char **where)
{
	struct mnttab search = { 0 }, entry;

	/*
	 * Search for the entry in /etc/mnttab.  We don't bother getting the
	 * mountpoint, as we can just search for the special device.  This will
	 * also let us find mounts when the mountpoint is 'legacy'.
	 */
	search.mnt_special = (char *)special;
	search.mnt_fstype = MNTTYPE_ZFS;

#ifndef __APPLE__
	rewind(zfs_hdl->libzfs_mnttab);
#endif
	if (getmntany(zfs_hdl->libzfs_mnttab, &entry, &search) != 0)
		return (B_FALSE);

	if (where != NULL)
		*where = zfs_strdup(zfs_hdl, entry.mnt_mountp);

	return (B_TRUE);
}

boolean_t
zfs_is_mounted(zfs_handle_t *zhp, char **where)
{
	return (is_mounted(zhp->zfs_hdl, zfs_get_name(zhp), where));
}

/*
 * Returns true if the given dataset is mountable, false otherwise.  Returns the
 * mountpoint in 'buf'.
 */
static boolean_t
zfs_is_mountable(zfs_handle_t *zhp, char *buf, size_t buflen,
    zfs_source_t *source)
{
	char sourceloc[ZFS_MAXNAMELEN];
	zfs_source_t sourcetype;

	if (!zfs_prop_valid_for_type(ZFS_PROP_MOUNTPOINT, zhp->zfs_type))
		return (B_FALSE);

	verify(zfs_prop_get(zhp, ZFS_PROP_MOUNTPOINT, buf, buflen,
	    &sourcetype, sourceloc, sizeof (sourceloc), B_FALSE) == 0);

	if (strcmp(buf, ZFS_MOUNTPOINT_NONE) == 0 ||
	    strcmp(buf, ZFS_MOUNTPOINT_LEGACY) == 0)
		return (B_FALSE);

	if (!zfs_prop_get_int(zhp, ZFS_PROP_CANMOUNT))
		return (B_FALSE);

#ifndef	__APPLE__
	if (zfs_prop_get_int(zhp, ZFS_PROP_ZONED) &&
	    getzoneid() == GLOBAL_ZONEID)
		return (B_FALSE);
#endif /*!__APPLE__*/

	if (source)
		*source = sourcetype;

	return (B_TRUE);
}

#ifdef __APPLE__

struct zfs_mount_args {
	const char	*fspec;		/* block special device to mount */
	int	flags; 
};

#define MOUNT_POINT_COOKIE		".autodiskmounted"
#define MOUNT_POINT_CUSTOM_ICON		".VolumeIcon.icns"
#define CUSTOM_ICON_PATH		"/System/Library/Filesystems/zfs.fs/Contents/Resources/VolumeIcon.icns"

#endif

/*
 * Mount the given filesystem.
 */
int
zfs_mount(zfs_handle_t *zhp, const char *options, int flags)
{
	struct stat buf;
	char mountpoint[ZFS_MAXPROPLEN];
	char mntopts[MNT_LINE_MAX];
	libzfs_handle_t *hdl = zhp->zfs_hdl;
#ifdef __APPLE__
	struct zfs_mount_args mnt_args;
	char  path[MAXPATHLEN];
	FILE *  file;
#endif

	if (options == NULL)
		mntopts[0] = '\0';
	else
		(void) strlcpy(mntopts, options, sizeof (mntopts));

	if (!zfs_is_mountable(zhp, mountpoint, sizeof (mountpoint), NULL))
		return (0);

	/* Create the directory if it doesn't already exist */
	if (lstat(mountpoint, &buf) != 0) {
		if (mkdirp(mountpoint, 0755) != 0) {
			zfs_error_aux(hdl, dgettext(TEXT_DOMAIN,
			    "failed to create mountpoint"));
			return (zfs_error_fmt(hdl, EZFS_MOUNTFAILED,
			    dgettext(TEXT_DOMAIN, "cannot mount '%s'"),
			    mountpoint));
		}
#ifdef __APPLE__
		/*
		 * Create the mount point cookie file.
		 */
		snprintf(path, MAXPATHLEN, "%s/%s", mountpoint, MOUNT_POINT_COOKIE);
		file = fopen( path, "w" );
		if ( file )
			fclose( file );
#endif
	}

#ifndef __APPLE__
	/*
	 * Determine if the mountpoint is empty.  If so, refuse to perform the
	 * mount.  We don't perform this check if MS_OVERLAY is specified, which
	 * would defeat the point.  We also avoid this check if 'remount' is
	 * specified.
	 */
	if ((flags & MS_OVERLAY) == 0 &&
	    strstr(mntopts, MNTOPT_REMOUNT) == NULL &&
	    !dir_is_empty(mountpoint)) {
		zfs_error_aux(hdl, dgettext(TEXT_DOMAIN,
		    "directory is not empty"));
		return (zfs_error_fmt(hdl, EZFS_MOUNTFAILED,
		    dgettext(TEXT_DOMAIN, "cannot mount '%s'"), mountpoint));
	}
#endif /*!__APPLE__*/

	/* perform the mount */
#ifdef __APPLE__
	if (options)
		printf("zfs_mount: unused options: \"%s\"\n", mntopts);
	mnt_args.fspec = zfs_get_name(zhp);
	if (mount(MNTTYPE_ZFS, mountpoint, flags, &mnt_args) != 0) {
#else
	if (mount(zfs_get_name(zhp), mountpoint, MS_OPTIONSTR | flags,
	    MNTTYPE_ZFS, NULL, 0, mntopts, sizeof (mntopts)) != 0) {
#endif
		/*
		 * Generic errors are nasty, but there are just way too many
		 * from mount(), and they're well-understood.  We pick a few
		 * common ones to improve upon.
		 */
		if (errno == EBUSY) {
			zfs_error_aux(hdl, dgettext(TEXT_DOMAIN,
			    "mountpoint or dataset is busy"));
		} else if (errno == EPERM) {
			zfs_error_aux(hdl, dgettext(TEXT_DOMAIN,
			    "Insufficient privileges"));
		} else {
			zfs_error_aux(hdl, strerror(errno));
		}

		return (zfs_error_fmt(hdl, EZFS_MOUNTFAILED,
		    dgettext(TEXT_DOMAIN, "cannot mount '%s'"),
		    zhp->zfs_name));
	}
#ifdef __APPLE__
	/*
	 * For a root file system, add a volume icon.
	 */
	if (strpbrk(mnt_args.fspec, "/") == NULL) {
		ssize_t  attrsize;
		u_int16_t finderinfo[16];
		struct stat sbuf;

		/* Tag the root directory as having a custom icon. */
		attrsize = getxattr(mountpoint, XATTR_FINDERINFO_NAME, &finderinfo,
		                    sizeof (finderinfo), 0, 0);
		if (attrsize != sizeof (finderinfo))
			(void) memset(&finderinfo, 0, sizeof (finderinfo));

		finderinfo[4] |= OSSwapHostToBigInt16(0x0400);

		(void) setxattr(mountpoint, XATTR_FINDERINFO_NAME, &finderinfo,
		                sizeof (finderinfo), 0, 0);

		snprintf(path, MAXPATHLEN, "%s/%s", mountpoint, MOUNT_POINT_CUSTOM_ICON);
		if ((stat(path, &sbuf) != 0 || sbuf.st_size == 0) &&
		    (stat(CUSTOM_ICON_PATH, &sbuf) == 0 && sbuf.st_size > 0)) {
			FILE *  srcfile;
			void * buf;

			srcfile = fopen(CUSTOM_ICON_PATH, "r");
			file = fopen(path, "w");

			if (srcfile && file) {
				/* Copy the custom icon to the root directory */
				buf = malloc(sbuf.st_size);
				if (fread(buf, 1, sbuf.st_size, srcfile) == sbuf.st_size)
					(void) fwrite(buf, 1, sbuf.st_size, file);
				free(buf);

				/* Init the custom icon's Finder Info. */
				(void) memset(&finderinfo, 0, sizeof (finderinfo));
				finderinfo[4] = OSSwapHostToBigInt16(0x4000);
				(void) setxattr(path, XATTR_FINDERINFO_NAME,
				                &finderinfo, sizeof (finderinfo), 0, 0);
			}
			if (srcfile)
				fclose(srcfile);
			if (file)
				fclose(file);
		}
	}
#endif
	return (0);
}

/*
 * Unmount a single filesystem.
 */
static int
unmount_one(libzfs_handle_t *hdl, const char *mountpoint, int flags)
{
	if (unmount(mountpoint, flags) != 0) {
		zfs_error_aux(hdl, strerror(errno));
		return (zfs_error_fmt(hdl, EZFS_UMOUNTFAILED,
		    dgettext(TEXT_DOMAIN, "cannot unmount '%s'"),
		    mountpoint));
	}

	return (0);
}

/*
 * Unmount the given filesystem.
 */
int
zfs_unmount(zfs_handle_t *zhp, const char *mountpoint, int flags)
{
	struct mnttab search = { 0 }, entry;
	char *mntpt = NULL;

	/* check to see if need to unmount the filesystem */
	search.mnt_special = zhp->zfs_name;
	search.mnt_fstype = MNTTYPE_ZFS;
#ifndef __APPLE__
	rewind(zhp->zfs_hdl->libzfs_mnttab);
#endif /*!__APPLE__*/
	if (mountpoint != NULL || ((zfs_get_type(zhp) == ZFS_TYPE_FILESYSTEM) &&
	    getmntany(zhp->zfs_hdl->libzfs_mnttab, &entry, &search) == 0)) {

		/*
		 * mountpoint may have come from a call to
		 * getmnt/getmntany if it isn't NULL. If it is NULL,
		 * we know it comes from getmntany which can then get
		 * overwritten later. We strdup it to play it safe.
		 */
		if (mountpoint == NULL)
			mntpt = zfs_strdup(zhp->zfs_hdl, entry.mnt_mountp);
		else
			mntpt = zfs_strdup(zhp->zfs_hdl, mountpoint);

		/*
		 * Unshare and unmount the filesystem
		 */
		if (zfs_unshare_nfs(zhp, mntpt) != 0)
			return (-1);

		if (unmount_one(zhp->zfs_hdl, mntpt, flags) != 0) {
			free(mntpt);
			(void) zfs_share_nfs(zhp);
			return (-1);
		}
		free(mntpt);
	}

	return (0);
}

/*
 * Unmount this filesystem and any children inheriting the mountpoint property.
 * To do this, just act like we're changing the mountpoint property, but don't
 * remount the filesystems afterwards.
 */
int
zfs_unmountall(zfs_handle_t *zhp, int flags)
{
	prop_changelist_t *clp;
	int ret;

	clp = changelist_gather(zhp, ZFS_PROP_MOUNTPOINT, flags);
	if (clp == NULL)
		return (-1);

	ret = changelist_prefix(clp);
	changelist_free(clp);

	return (ret);
}

boolean_t
zfs_is_shared(zfs_handle_t *zhp)
{
	if (ZFS_IS_VOLUME(zhp))
		return (zfs_is_shared_iscsi(zhp));

	return (zfs_is_shared_nfs(zhp, NULL));
}

int
zfs_share(zfs_handle_t *zhp)
{
	if (ZFS_IS_VOLUME(zhp))
		return (zfs_share_iscsi(zhp));

	return (zfs_share_nfs(zhp));
}

int
zfs_unshare(zfs_handle_t *zhp)
{
	if (ZFS_IS_VOLUME(zhp))
		return (zfs_unshare_iscsi(zhp));

	return (zfs_unshare_nfs(zhp, NULL));
}

/*
 * Check to see if the filesystem is currently shared.
 */
boolean_t
zfs_is_shared_nfs(zfs_handle_t *zhp, char **where)
{
	char *mountpoint;

	if (!zfs_is_mounted(zhp, &mountpoint))
		return (B_FALSE);

	if (is_shared(zhp->zfs_hdl, mountpoint)) {
		if (where != NULL)
			*where = mountpoint;
		else
			free(mountpoint);
		return (B_TRUE);
	} else {
		free(mountpoint);
		return (B_FALSE);
	}
}

/*
 * Make sure things will work if libshare isn't installed by using
 * wrapper functions that check to see that the pointers to functions
 * initialized in _zfs_init_libshare() are actually present.
 */
#ifndef __APPLE__
static sa_handle_t (*_sa_init)(int);
static void (*_sa_fini)(sa_handle_t);
static sa_share_t (*_sa_find_share)(sa_handle_t, char *);
static int (*_sa_enable_share)(sa_share_t, char *);
static int (*_sa_disable_share)(sa_share_t, char *);
static char *(*_sa_errorstr)(int);
static int (*_sa_parse_legacy_options)(sa_group_t, char *, char *);

/*
 * _zfs_init_libshare()
 *
 * Find the libshare.so.1 entry points that we use here and save the
 * values to be used later. This is triggered by the runtime loader.
 * Make sure the correct ISA version is loaded.
 */

#pragma init(_zfs_init_libshare)
static void
_zfs_init_libshare(void)
{
	void *libshare;
	char path[MAXPATHLEN];
	char isa[MAXISALEN];

#if defined(_LP64)
	if (sysinfo(SI_ARCHITECTURE_64, isa, MAXISALEN) == -1)
		isa[0] = '\0';
#else
	isa[0] = '\0';
#endif
	(void) snprintf(path, MAXPATHLEN,
	    "/usr/lib/%s/libshare.so.1", isa);

	if ((libshare = dlopen(path, RTLD_LAZY | RTLD_GLOBAL)) != NULL) {
		_sa_init = (sa_handle_t (*)(int))dlsym(libshare, "sa_init");
		_sa_fini = (void (*)(sa_handle_t))dlsym(libshare, "sa_fini");
		_sa_find_share = (sa_share_t (*)(sa_handle_t, char *))
		    dlsym(libshare, "sa_find_share");
		_sa_enable_share = (int (*)(sa_share_t, char *))dlsym(libshare,
		    "sa_enable_share");
		_sa_disable_share = (int (*)(sa_share_t, char *))dlsym(libshare,
		    "sa_disable_share");
		_sa_errorstr = (char *(*)(int))dlsym(libshare, "sa_errorstr");
		_sa_parse_legacy_options = (int (*)(sa_group_t, char *, char *))
		    dlsym(libshare, "sa_parse_legacy_options");
		if (_sa_init == NULL || _sa_fini == NULL ||
		    _sa_find_share == NULL || _sa_enable_share == NULL ||
		    _sa_disable_share == NULL || _sa_errorstr == NULL ||
		    _sa_parse_legacy_options == NULL) {
			_sa_init = NULL;
			_sa_fini = NULL;
			_sa_disable_share = NULL;
			_sa_enable_share = NULL;
			_sa_errorstr = NULL;
			_sa_parse_legacy_options = NULL;
			(void) dlclose(libshare);
		}
	}
}

/*
 * zfs_init_libshare(zhandle, service)
 *
 * Initialize the libshare API if it hasn't already been initialized.
 * In all cases it returns 0 if it succeeded and an error if not. The
 * service value is which part(s) of the API to initialize and is a
 * direct map to the libshare sa_init(service) interface.
 */

int
zfs_init_libshare(libzfs_handle_t *zhandle, int service)
{
	int ret = SA_OK;

	if (_sa_init == NULL)
		ret = SA_CONFIG_ERR;

	if (ret == SA_OK && zhandle && zhandle->libzfs_sharehdl == NULL)
		zhandle->libzfs_sharehdl = _sa_init(service);

	if (ret == SA_OK && zhandle->libzfs_sharehdl == NULL)
		ret = SA_NO_MEMORY;

	return (ret);
}

/*
 * zfs_uninit_libshare(zhandle)
 *
 * Uninitialize the libshare API if it hasn't already been
 * uninitialized. It is OK to call multiple times.
 */

void
zfs_uninit_libshare(libzfs_handle_t *zhandle)
{

	if (zhandle != NULL && zhandle->libzfs_sharehdl != NULL) {
		if (_sa_fini != NULL)
			_sa_fini(zhandle->libzfs_sharehdl);
		zhandle->libzfs_sharehdl = NULL;
	}
}

/*
 * zfs_parse_options(options, proto)
 *
 * Call the legacy parse interface to get the protocol specific
 * options using the NULL arg to indicate that this is a "parse" only.
 */

int
zfs_parse_options(char *options, char *proto)
{
	int ret;

	if (_sa_parse_legacy_options != NULL)
		ret = _sa_parse_legacy_options(NULL, options, proto);
	else
		ret = SA_CONFIG_ERR;
	return (ret);
}

/*
 * zfs_sa_find_share(handle, path)
 *
 * wrapper around sa_find_share to find a share path in the
 * configuration.
 */

static sa_share_t
zfs_sa_find_share(sa_handle_t handle, char *path)
{
	if (_sa_find_share != NULL)
		return (_sa_find_share(handle, path));
	return (NULL);
}

/*
 * zfs_sa_enable_share(share, proto)
 *
 * Wrapper for sa_enable_share which enables a share for a specified
 * protocol.
 */

static int
zfs_sa_enable_share(sa_share_t share, char *proto)
{
	if (_sa_enable_share != NULL)
		return (_sa_enable_share(share, proto));
	return (SA_CONFIG_ERR);
}

/*
 * zfs_sa_disable_share(share, proto)
 *
 * Wrapper for sa_enable_share which disables a share for a specified
 * protocol.
 */

static int
zfs_sa_disable_share(sa_share_t share, char *proto)
{
	if (_sa_disable_share != NULL)
		return (_sa_disable_share(share, proto));
	return (SA_CONFIG_ERR);
}
#endif /*!APPLE*/

/*
 * Share the given filesystem according to the options in 'sharenfs'.  We rely
 * on "libshare" to the dirty work for us.
 */

int
zfs_share_nfs(zfs_handle_t *zhp)
{
	char mountpoint[ZFS_MAXPROPLEN];
	char shareopts[ZFS_MAXPROPLEN];
	libzfs_handle_t *hdl; // = zhp->zfs_hdl;
#ifndef __APPLE__
	sa_share_t share;
#endif

	int ret;

	if (!zfs_is_mountable(zhp, mountpoint, sizeof (mountpoint), NULL))
		return (0);

	/*
	 * Return success if there are no share options.
	 */
	if (zfs_prop_get(zhp, ZFS_PROP_SHARENFS, shareopts, sizeof (shareopts),
	    NULL, NULL, 0, B_FALSE) != 0 ||
	    strcmp(shareopts, "off") == 0)
		return (0);

#ifndef	__APPLE__
	/*
	 * If the 'zoned' property is set, then zfs_is_mountable() will have
	 * already bailed out if we are in the global zone.  But local
	 * zones cannot be NFS servers, so we ignore it for local zones as well.
	 */
	if (zfs_prop_get_int(zhp, ZFS_PROP_ZONED))
		return (0);

	if ((ret = zfs_init_libshare(hdl, SA_INIT_SHARE_API)) != SA_OK) {
		(void) zfs_error_fmt(hdl, EZFS_SHARENFSFAILED,
		    dgettext(TEXT_DOMAIN, "cannot share '%s': %s"),
		    zfs_get_name(zhp), _sa_errorstr(ret));
		return (-1);
	}
	share = zfs_sa_find_share(hdl->libzfs_sharehdl, mountpoint);
	if (share != NULL) {
		int err;
		err = zfs_sa_enable_share(share, "nfs");
		if (err != SA_OK) {
			(void) zfs_error_fmt(hdl, EZFS_SHARENFSFAILED,
			    dgettext(TEXT_DOMAIN, "cannot share '%s'"),
			    zfs_get_name(zhp));
			return (-1);
		}
	} else {
		(void) zfs_error_fmt(hdl, EZFS_SHARENFSFAILED,
		    dgettext(TEXT_DOMAIN, "cannot share '%s'"),
		    zfs_get_name(zhp));
		return (-1);
	}
#endif /* !__APPLE__ */
	return (0);
}

/*
 * Unshare a filesystem by mountpoint.
 */
static int
unshare_one(libzfs_handle_t *hdl, const char *name, const char *mountpoint)
{
#ifndef __APPLE__
	sa_share_t share;
#endif
	int err;
	char *mntpt;

	/*
	 * Mountpoint could get trashed if libshare calls getmntany
	 * which id does during API initialization, so strdup the
	 * value.
	 */
	mntpt = zfs_strdup(hdl, mountpoint);

#ifndef __APPLE__
	/* make sure libshare initialized */
	if ((err = zfs_init_libshare(hdl, SA_INIT_SHARE_API)) != SA_OK) {
		free(mntpt);	/* don't need the copy anymore */
		return (zfs_error_fmt(hdl, EZFS_SHARENFSFAILED,
		    dgettext(TEXT_DOMAIN, "cannot unshare '%s': %s"),
		    name, _sa_errorstr(err)));
	}

	share = zfs_sa_find_share(hdl->libzfs_sharehdl, mntpt);
#endif
	free(mntpt);	/* don't need the copy anymore */
#ifndef __APPLE__
	if (share != NULL) {
		err = zfs_sa_disable_share(share, "nfs");
		if (err != SA_OK) {
			return (zfs_error_fmt(hdl, EZFS_UNSHARENFSFAILED,
			    dgettext(TEXT_DOMAIN, "cannot unshare '%s': %s"),
			    name, _sa_errorstr(err)));
		}
	} else {
		return (zfs_error_fmt(hdl, EZFS_UNSHARENFSFAILED,
		    dgettext(TEXT_DOMAIN, "cannot unshare '%s': not found"),
		    name));
	}
#endif
	return (0);
}

/*
 * Unshare the given filesystem.
 */
int
zfs_unshare_nfs(zfs_handle_t *zhp, const char *mountpoint)
{
	struct mnttab search = { 0 }, entry;
	char *mntpt = NULL;

	/* check to see if need to unmount the filesystem */
	search.mnt_special = (char *)zfs_get_name(zhp);
	search.mnt_fstype = MNTTYPE_ZFS;

#ifndef __APPLE__
	rewind(zhp->zfs_hdl->libzfs_mnttab);
#endif /*!__APPLE__*/
	if (mountpoint != NULL)
		mountpoint = mntpt = zfs_strdup(zhp->zfs_hdl, mountpoint);

	if (mountpoint != NULL || ((zfs_get_type(zhp) == ZFS_TYPE_FILESYSTEM) &&
	    getmntany(zhp->zfs_hdl->libzfs_mnttab, &entry, &search) == 0)) {

		if (mountpoint == NULL)
			mountpoint = entry.mnt_mountp;

		if (is_shared(zhp->zfs_hdl, mountpoint) &&
		    unshare_one(zhp->zfs_hdl, zhp->zfs_name, mountpoint) != 0) {
			if (mntpt != NULL)
				free(mntpt);
			return (-1);
		}
	}
	if (mntpt != NULL)
		free(mntpt);

	return (0);
}

/*
 * Same as zfs_unmountall(), but for NFS unshares.
 */
int
zfs_unshareall_nfs(zfs_handle_t *zhp)
{
	prop_changelist_t *clp;
	int ret;

	clp = changelist_gather(zhp, ZFS_PROP_SHARENFS, 0);
	if (clp == NULL)
		return (-1);

	ret = changelist_unshare(clp);
	changelist_free(clp);

	return (ret);
}

/*
 * Remove the mountpoint associated with the current dataset, if necessary.
 * We only remove the underlying directory if:
 *
 *	- The mountpoint is not 'none' or 'legacy'
 *	- The mountpoint is non-empty
 *	- The mountpoint is the default or inherited
 *	- The 'zoned' property is set, or we're in a local zone
 *
 * Any other directories we leave alone.
 */
void
remove_mountpoint(zfs_handle_t *zhp)
{
	char mountpoint[ZFS_MAXPROPLEN];
	zfs_source_t source;

	if (!zfs_is_mountable(zhp, mountpoint, sizeof (mountpoint),
	    &source))
		return;

	if (source == ZFS_SRC_DEFAULT ||
	    source == ZFS_SRC_INHERITED) {
		/*
		 * Try to remove the directory, silently ignoring any errors.
		 * The filesystem may have since been removed or moved around,
		 * and this error isn't really useful to the administrator in
		 * any way.
		 */
#ifdef __APPLE__
		{
			char  path[MAXPATHLEN];
			/*
			 * Remove the mount point cookie file.
			 */
			snprintf(path, MAXPATHLEN, "%s/%s", mountpoint, MOUNT_POINT_COOKIE);
			(void) unlink(path);
		}
#endif
		(void) rmdir(mountpoint);
	}
}

boolean_t
zfs_is_shared_iscsi(zfs_handle_t *zhp)
{
#ifdef __APPLE__
	return (0);
#else
	/*
	 * If iscsi deamon isn't running then we aren't shared
	 */
	if (iscsitgt_svc_online && iscsitgt_svc_online() == 1)
		return (0);
	else
		return (iscsitgt_zfs_is_shared != NULL &&
		    iscsitgt_zfs_is_shared(zhp->zfs_name) != 0);
#endif
}

int
zfs_share_iscsi(zfs_handle_t *zhp)
{
#ifndef __APPLE__
	char shareopts[ZFS_MAXPROPLEN];
	const char *dataset = zhp->zfs_name;
	libzfs_handle_t *hdl = zhp->zfs_hdl;

	/*
	 * Return success if there are no share options.
	 */
	if (zfs_prop_get(zhp, ZFS_PROP_SHAREISCSI, shareopts,
	    sizeof (shareopts), NULL, NULL, 0, B_FALSE) != 0 ||
	    strcmp(shareopts, "off") == 0)
		return (0);

	if (iscsitgt_zfs_share == NULL || iscsitgt_zfs_share(dataset) != 0) {
		int error = EZFS_SHAREISCSIFAILED;

		/*
		 * If service isn't availabele and EPERM was
		 * returned then use special error.
		 */
		if (iscsitgt_svc_online && errno == EPERM &&
		    (iscsitgt_svc_online() != 0))
			error = EZFS_ISCSISVCUNAVAIL;

		return (zfs_error_fmt(hdl, error,
		    dgettext(TEXT_DOMAIN, "cannot share '%s'"), dataset));
	}
#endif /* !__APPLE__ */
	return (0);
}

int
zfs_unshare_iscsi(zfs_handle_t *zhp)
{
#ifndef __APPLE__
	const char *dataset = zfs_get_name(zhp);
	libzfs_handle_t *hdl = zhp->zfs_hdl;

	/*
	 * Return if the volume is not shared
	 */
	if (!zfs_is_shared_iscsi(zhp))
		return (0);

	/*
	 * If this fails with ENODEV it indicates that zvol wasn't shared so
	 * we should return success in that case.
	 */
	if (iscsitgt_zfs_unshare == NULL ||
	    (iscsitgt_zfs_unshare(dataset) != 0 && errno != ENODEV)) {
		if (errno == EPERM)
			zfs_error_aux(hdl, dgettext(TEXT_DOMAIN,
			    "Insufficient privileges to unshare iscsi"));
		return (zfs_error_fmt(hdl, EZFS_UNSHAREISCSIFAILED,
		    dgettext(TEXT_DOMAIN, "cannot unshare '%s'"), dataset));
	}
#endif /* !__APPLE__ */
	return (0);
}

typedef struct mount_cbdata {
	zfs_handle_t	**cb_datasets;
	int 		cb_used;
	int		cb_alloc;
} mount_cbdata_t;

static int
mount_cb(zfs_handle_t *zhp, void *data)
{
	mount_cbdata_t *cbp = data;

	if (!(zfs_get_type(zhp) & (ZFS_TYPE_FILESYSTEM | ZFS_TYPE_VOLUME))) {
		zfs_close(zhp);
		return (0);
	}

	if (cbp->cb_alloc == cbp->cb_used) {
		void *ptr;

		if ((ptr = zfs_realloc(zhp->zfs_hdl,
		    cbp->cb_datasets, cbp->cb_alloc * sizeof (void *),
		    cbp->cb_alloc * 2 * sizeof (void *))) == NULL)
			return (-1);
		cbp->cb_datasets = ptr;

		cbp->cb_alloc *= 2;
	}

	cbp->cb_datasets[cbp->cb_used++] = zhp;

	return (zfs_iter_children(zhp, mount_cb, cbp));
}

static int
dataset_cmp(const void *a, const void *b)
{
	zfs_handle_t **za = (zfs_handle_t **)a;
	zfs_handle_t **zb = (zfs_handle_t **)b;
	char mounta[MAXPATHLEN];
	char mountb[MAXPATHLEN];
	boolean_t gota, gotb;

	if ((gota = (zfs_get_type(*za) == ZFS_TYPE_FILESYSTEM)) != 0)
		verify(zfs_prop_get(*za, ZFS_PROP_MOUNTPOINT, mounta,
		    sizeof (mounta), NULL, NULL, 0, B_FALSE) == 0);
	if ((gotb = (zfs_get_type(*zb) == ZFS_TYPE_FILESYSTEM)) != 0)
		verify(zfs_prop_get(*zb, ZFS_PROP_MOUNTPOINT, mountb,
		    sizeof (mountb), NULL, NULL, 0, B_FALSE) == 0);

	if (gota && gotb)
		return (strcmp(mounta, mountb));

	if (gota)
		return (-1);
	if (gotb)
		return (1);

	return (strcmp(zfs_get_name(a), zfs_get_name(b)));
}

/*
 * Mount and share all datasets within the given pool.  This assumes that no
 * datasets within the pool are currently mounted.  Because users can create
 * complicated nested hierarchies of mountpoints, we first gather all the
 * datasets and mountpoints within the pool, and sort them by mountpoint.  Once
 * we have the list of all filesystems, we iterate over them in order and mount
 * and/or share each one.
 */
//#pragma weak zpool_mount_datasets = zpool_enable_datasets
int
zpool_enable_datasets(zpool_handle_t *zhp, const char *mntopts, int flags)
{
	mount_cbdata_t cb = { 0 };
	libzfs_handle_t *hdl = zhp->zpool_hdl;
	zfs_handle_t *zfsp;
	int i, ret = -1;
	int *good;

	/*
	 * Gather all datasets within the pool.
	 */
	if ((cb.cb_datasets = zfs_alloc(hdl, 4 * sizeof (void *))) == NULL)
		return (-1);
	cb.cb_alloc = 4;

	if ((zfsp = zfs_open(hdl, zhp->zpool_name, ZFS_TYPE_ANY)) == NULL)
		goto out;

	cb.cb_datasets[0] = zfsp;
	cb.cb_used = 1;

	if (zfs_iter_children(zfsp, mount_cb, &cb) != 0)
		goto out;

	/*
	 * Sort the datasets by mountpoint.
	 */
	qsort(cb.cb_datasets, cb.cb_used, sizeof (void *), dataset_cmp);

	/*
	 * And mount all the datasets, keeping track of which ones
	 * succeeded or failed. By using zfs_alloc(), the good pointer
	 * will always be non-NULL.
	 */
	good = zfs_alloc(zhp->zpool_hdl, cb.cb_used * sizeof (int));
	ret = 0;
	for (i = 0; i < cb.cb_used; i++) {
		if (zfs_mount(cb.cb_datasets[i], mntopts, flags) != 0)
			ret = -1;
		else
			good[i] = 1;
	}
	/*
	 * Then share all the ones that need to be shared. This needs
	 * to be a separate pass in order to avoid excessive reloading
	 * of the configuration. Good should never be NULL since
	 * zfs_alloc is supposed to exit if memory isn't available.
	 */
#ifndef __APPLE__
	zfs_uninit_libshare(hdl);
#endif
	for (i = 0; i < cb.cb_used; i++) {
		if (good[i] && zfs_share(cb.cb_datasets[i]) != 0)
			ret = -1;
	}

	free(good);

out:
	for (i = 0; i < cb.cb_used; i++)
		zfs_close(cb.cb_datasets[i]);
	free(cb.cb_datasets);

	return (ret);
}


static int
zvol_cb(const char *dataset, void *data)
{
	libzfs_handle_t *hdl = data;
	zfs_handle_t *zhp;

	/*
	 * Ignore snapshots and ignore failures from non-existant datasets.
	 */
	if (strchr(dataset, '@') != NULL ||
	    (zhp = zfs_open(hdl, dataset, ZFS_TYPE_VOLUME)) == NULL)
		return (0);

	if (zfs_unshare_iscsi(zhp) != 0)
		return (-1);

	zfs_close(zhp);

	return (0);
}

static int
mountpoint_compare(const void *a, const void *b)
{
	const char *mounta = *((char **)a);
	const char *mountb = *((char **)b);

	return (strcmp(mountb, mounta));
}

/*
 * Unshare and unmount all datasets within the given pool.  We don't want to
 * rely on traversing the DSL to discover the filesystems within the pool,
 * because this may be expensive (if not all of them are mounted), and can fail
 * arbitrarily (on I/O error, for example).  Instead, we walk /etc/mnttab and
 * gather all the filesystems that are currently mounted.
 */
//#pragma weak zpool_unmount_datasets = zpool_disable_datasets
int
zpool_disable_datasets(zpool_handle_t *zhp, boolean_t force)
{
	int used, alloc;
#ifdef __APPLE__
	struct statfs *sfsp;
	int nitems;
#else
	struct mnttab entry;
#endif
	size_t namelen;
	char **mountpoints = NULL;
	zfs_handle_t **datasets = NULL;
	libzfs_handle_t *hdl = zhp->zpool_hdl;
	int i;
	int ret = -1;
	int flags = (force ? MNT_FORCE : 0);

	/*
	 * First unshare all zvols.
	 */
	if (zpool_iter_zvol(zhp, zvol_cb, hdl) != 0)
		return (-1);

	namelen = strlen(zhp->zpool_name);

#ifdef __APPLE__
	if ((nitems = getmntinfo(&sfsp, MNT_WAIT)) == 0) {
		return (ret);
	}
	used = alloc = 0;
	while (nitems--) {
		/*
		 * Ignore non-ZFS entries.
		 */
		if (strcmp(sfsp->f_fstypename, MNTTYPE_ZFS) != 0) {
			++sfsp;
			continue;
		}
		/*
		 * Ignore filesystems not within this pool.
		 */
		if (strncmp(sfsp->f_mntfromname, zhp->zpool_name, namelen) != 0 ||
		    (sfsp->f_mntfromname[namelen] != '/' &&
		     sfsp->f_mntfromname[namelen] != '\0')) {
			++sfsp;
			continue;
		}
		/*
		 * At this point we've found a filesystem within our pool.  Add
		 * it to our growing list.
		 */
		if (used == alloc) {
			if (alloc == 0) {
				if ((mountpoints = zfs_alloc(hdl,
				    8 * sizeof (void *))) == NULL)
					goto out;

				if ((datasets = zfs_alloc(hdl,
				    8 * sizeof (void *))) == NULL)
					goto out;

				alloc = 8;
			} else {
				void *ptr;

				if ((ptr = zfs_realloc(hdl, mountpoints,
				    alloc * sizeof (void *),
				    alloc * 2 * sizeof (void *))) == NULL)
					goto out;
				mountpoints = ptr;

				if ((ptr = zfs_realloc(hdl, datasets,
				    alloc * sizeof (void *),
				    alloc * 2 * sizeof (void *))) == NULL)
					goto out;
				datasets = ptr;

				alloc *= 2;
			}
		}

		if ((mountpoints[used] = zfs_strdup(hdl, sfsp->f_mntonname)) == NULL)
			goto out;

		/*
		 * This is allowed to fail, in case there is some I/O error.  It
		 * is only used to determine if we need to remove the underlying
		 * mountpoint, so failure is not fatal.
		 */
		datasets[used] = make_dataset_handle(hdl, sfsp->f_mntfromname);

		used++;
		++sfsp;
	}
#else
	rewind(hdl->libzfs_mnttab);
	used = alloc = 0;
	while (getmntent(hdl->libzfs_mnttab, &entry) == 0) {
		/*
		 * Ignore non-ZFS entries.
		 */
		if (entry.mnt_fstype == NULL ||
		    strcmp(entry.mnt_fstype, MNTTYPE_ZFS) != 0)
			continue;

		/*
		 * Ignore filesystems not within this pool.
		 */
		if (entry.mnt_mountp == NULL ||
		    strncmp(entry.mnt_special, zhp->zpool_name, namelen) != 0 ||
		    (entry.mnt_special[namelen] != '/' &&
		    entry.mnt_special[namelen] != '\0'))
			continue;

		/*
		 * At this point we've found a filesystem within our pool.  Add
		 * it to our growing list.
		 */
		if (used == alloc) {
			if (alloc == 0) {
				if ((mountpoints = zfs_alloc(hdl,
				    8 * sizeof (void *))) == NULL)
					goto out;

				if ((datasets = zfs_alloc(hdl,
				    8 * sizeof (void *))) == NULL)
					goto out;

				alloc = 8;
			} else {
				void *ptr;

				if ((ptr = zfs_realloc(hdl, mountpoints,
				    alloc * sizeof (void *),
				    alloc * 2 * sizeof (void *))) == NULL)
					goto out;
				mountpoints = ptr;

				if ((ptr = zfs_realloc(hdl, datasets,
				    alloc * sizeof (void *),
				    alloc * 2 * sizeof (void *))) == NULL)
					goto out;
				datasets = ptr;

				alloc *= 2;
			}
		}

		if ((mountpoints[used] = zfs_strdup(hdl,
		    entry.mnt_mountp)) == NULL)
			goto out;

		/*
		 * This is allowed to fail, in case there is some I/O error.  It
		 * is only used to determine if we need to remove the underlying
		 * mountpoint, so failure is not fatal.
		 */
		datasets[used] = make_dataset_handle(hdl, entry.mnt_special);

		used++;
	}
#endif

	/*
	 * At this point, we have the entire list of filesystems, so sort it by
	 * mountpoint.
	 */
	qsort(mountpoints, used, sizeof (char *), mountpoint_compare);

	/*
	 * Walk through and first unshare everything.
	 */
	for (i = 0; i < used; i++) {
		if (is_shared(hdl, mountpoints[i]) &&
		    unshare_one(hdl, mountpoints[i], mountpoints[i]) != 0)
			goto out;
	}

	/*
	 * Now unmount everything, removing the underlying directories as
	 * appropriate.
	 */
	for (i = 0; i < used; i++) {
		if (unmount_one(hdl, mountpoints[i], flags) != 0)
			goto out;
	}

	for (i = 0; i < used; i++) {
		if (datasets[i])
			remove_mountpoint(datasets[i]);
	}

	ret = 0;
out:
	for (i = 0; i < used; i++) {
		if (datasets[i])
			zfs_close(datasets[i]);
		free(mountpoints[i]);
	}
	free(datasets);
	free(mountpoints);

	return (ret);
}

#ifdef __APPLE__
int
getmntany(FILE *fp, struct mnttab *mgetp, struct mnttab *mrefp)
{
	struct statfs *sfsp;
	int nitems;

	nitems = getmntinfo(&sfsp, MNT_WAIT);
	
	while (nitems-- > 0) {
		if (strcmp(mrefp->mnt_fstype, sfsp->f_fstypename) == 0 &&
		    strcmp(mrefp->mnt_special, sfsp->f_mntfromname) == 0) {
			mgetp->mnt_special = sfsp->f_mntfromname;
			mgetp->mnt_mountp = sfsp->f_mntonname;
			mgetp->mnt_fstype = sfsp->f_fstypename;
			mgetp->mnt_mntopts = "";
			return (0);
		}
		++sfsp;
	}
	return (-1);
}

char *
mntopt(char **p)
{
	char *cp = *p;
	char *retstr;

	while (*cp && isspace(*cp))
		cp++;

	retstr = cp;
	while (*cp && *cp != ',')
		cp++;

	if (*cp) {
		*cp = '\0';
		cp++;
	}

	*p = cp;
	return (retstr);
}

char *
hasmntopt(struct mnttab *mnt, char *opt)
{
	char tmpopts[MNT_LINE_MAX];
	char *f, *opts = tmpopts;

	if (mnt->mnt_mntopts == NULL)
		return (NULL);
	(void) strcpy(opts, mnt->mnt_mntopts);
	f = mntopt(&opts);
	for (; *f; f = mntopt(&opts)) {
		if (strncmp(opt, f, strlen(opt)) == 0)
			return (f - tmpopts + mnt->mnt_mntopts);
	}
	return (NULL);
}
#endif /* __APPLE__ */

