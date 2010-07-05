/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
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
 * Copyright 2004 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 */

#pragma ident	"%Z%%M%	%I%	%E% SMI"

#include <sys/types.h>
#include <sys/id_space.h>
#include <sys/debug.h>

/*
 * ID Spaces
 *
 *   The id_space_t provides a simple implementation of a managed range of
 *   integer identifiers using a vmem arena.  An ID space guarantees that the
 *   next identifer returned by an allocation is larger than the previous one,
 *   unless there are no larger slots remaining in the range.  In this case,
 *   the ID space will return the first available slot in the lower part of the
 *   range (viewing the previous identifier as a partitioning element).  If no
 *   slots are available, id_alloc() will sleep until an identifier becomes
 *   available.  Accordingly, id_space allocations must be initiated from
 *   contexts where sleeping is acceptable.  id_alloc_nosleep() will return
 *   -1 if no slots are available or if the system is low on memory.  If
 *   id_alloc_nosleep() fails, callers should not try to extend the ID
 *   space.  This is to avoid making a possible low-memory situation
 *   worse.
 *
 *   As an ID space is designed for representing a range of id_t's, there
 *   is a preexisting maximal range: [0, MAXUID].  ID space requests
 *   outside that range will fail on a DEBUG kernel.
 *
 *   (Presently, the id_space_t abstraction supports only direct allocations; ID
 *   reservation, in which an ID is allocated but placed in a internal
 *   dictionary for later use, should be added when a consuming subsystem
 *   arrives.)
 */

/*
 * Create an arena to represent the range [low, high).
 * Caller must be in a context in which VM_SLEEP is legal.
 */
id_space_t *
id_space_create(const char *name, id_t low, id_t high)
{
	ASSERT(low >= 0);
	ASSERT(low < high);

	return (vmem_create(name, (void *)(uintptr_t)(low + 1), high - low, 1,
	    NULL, NULL, NULL, 0, VM_SLEEP | VMC_IDENTIFIER));
}

/*
 * Destroy a previously created ID space.
 * No restrictions on caller's context.
 */
void
id_space_destroy(id_space_t *isp)
{
	vmem_destroy(isp);
}

void
id_space_extend(id_space_t *isp, id_t low, id_t high)
{
	(void) vmem_add(isp,
	    (void *)(uintptr_t)(low + 1), high - low, VM_SLEEP);
}

/*
 * Allocate an id_t from specified ID space.
 * Caller must be in a context in which VM_SLEEP is legal.
 */
id_t
id_alloc(id_space_t *isp)
{
	return ((id_t)(uintptr_t)
	    vmem_alloc(isp, 1, VM_SLEEP | VM_NEXTFIT) - 1);
}

/*
 * Allocate an id_t from specified ID space.
 * Returns -1 on failure (see module block comments for more information on
 * failure modes).
 */
id_t
id_alloc_nosleep(id_space_t *isp)
{
	return ((id_t)(uintptr_t)
	    vmem_alloc(isp, 1, VM_NOSLEEP | VM_NEXTFIT) - 1);
}

/*
 * Free a previously allocated ID.
 * No restrictions on caller's context.
 */
void
id_free(id_space_t *isp, id_t id)
{
	vmem_free(isp, (void *)(uintptr_t)(id + 1), 1);
}