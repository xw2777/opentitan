// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
<%
import textwrap
import topgen.lib as lib

has_pwrmgr = lib.find_module(top['module'], 'pwrmgr')
has_pinmux = lib.find_module(top['module'], 'pinmux')
has_alert_handler = lib.find_module(top['module'], 'alert_handler') or top['name'] == 'englishbreakfast'
has_clkmgr = lib.find_module(top['module'], 'clkmgr')
has_rstmgr = lib.find_module(top['module'], 'rstmgr')
%>\
${helper.file_header.render()}
// This file was generated automatically.
// Please do not modify content of this file directly.
// File generated by using template: "toplevel.rs.tpl"
// To regenerate this file follow OpenTitan topgen documentations.

#![allow(dead_code)]

//! This file contains enums and consts for use within the Rust codebase.
//!
//! These definitions are for information that depends on the top-specific chip
//! configuration, which includes:
//! - Device Memory Information (for Peripherals and Memory)
//! - PLIC Interrupt ID Names and Source Mappings
//! - Alert ID Names and Source Mappings
% if has_pinmux:
//! - Pinmux Pin/Select Names
% endif
% if has_pwrmgr:
//! - Power Manager Wakeups
% endif

use core::convert::TryFrom;

% for (inst_name, if_name), region in helper.devices():
<%
    if_desc = inst_name if if_name is None else '{} device on {}'.format(if_name, inst_name)
    hex_base_addr = "0x{:X}".format(region.base_addr)
    hex_size_bytes = "0x{:X}".format(region.size_bytes)

    base_addr_name = region.base_addr_name(short=True).as_rust_const()
    size_bytes_name = region.size_bytes_name(short=True).as_rust_const()

%>\
/// Peripheral base address for ${if_desc} in top ${top["name"]}.
///
/// This should be used with #mmio_region_from_addr to access the memory-mapped
/// registers associated with the peripheral (usually via a DIF).
pub const ${base_addr_name}: usize = ${hex_base_addr};

/// Peripheral size for ${if_desc} in top ${top["name"]}.
///
/// This is the size (in bytes) of the peripheral's reserved memory area. All
/// memory-mapped registers associated with this peripheral should have an
/// address between #${base_addr_name} and
/// `${base_addr_name} + ${size_bytes_name}`.
pub const ${size_bytes_name}: usize = ${hex_size_bytes};

% endfor
% for name, region in helper.memories():
<%
    hex_base_addr = "0x{:X}".format(region.base_addr)
    hex_size_bytes = "0x{:X}".format(region.size_bytes)

    base_addr_name = region.base_addr_name(short=True).as_rust_const()
    size_bytes_name = region.size_bytes_name(short=True).as_rust_const()

%>\
/// Memory base address for ${name} in top ${top["name"]}.
pub const ${base_addr_name}: usize = ${hex_base_addr};

/// Memory size for ${name} in top ${top["name"]}.
pub const ${size_bytes_name}: usize = ${hex_size_bytes};

% endfor
/// PLIC Interrupt Source Peripheral.
///
/// Enumeration used to determine which peripheral asserted the corresponding
/// interrupt.
${helper.plic_sources.render(gen_cast=True)}

/// PLIC Interrupt Source.
///
/// Enumeration of all PLIC interrupt sources. The interrupt sources belonging to
/// the same peripheral are guaranteed to be consecutive.
${helper.plic_interrupts.render(gen_cast=True)}

/// PLIC Interrupt Target.
///
/// Enumeration used to determine which set of IE, CC, threshold registers to
/// access for a given interrupt target.
${helper.plic_targets.render()}
% if has_alert_handler:

/// Alert Handler Source Peripheral.
///
/// Enumeration used to determine which peripheral asserted the corresponding
/// alert.
${helper.alert_sources.render()}

/// Alert Handler Alert Source.
///
/// Enumeration of all Alert Handler Alert Sources. The alert sources belonging to
/// the same peripheral are guaranteed to be consecutive.
${helper.alert_alerts.render(gen_cast=True)}
% endif

/// PLIC Interrupt Source to Peripheral Map
///
/// This array is a mapping from `${helper.plic_interrupts.short_name.as_rust_type()}` to
/// `${helper.plic_sources.short_name.as_rust_type()}`.
${helper.plic_mapping.render_definition()}
% if has_alert_handler:

/// Alert Handler Alert Source to Peripheral Map
///
/// This array is a mapping from `${helper.alert_alerts.short_name.as_rust_type()}` to
/// `${helper.alert_sources.short_name.as_rust_type()}`.
${helper.alert_mapping.render_definition()}
% endif
% if has_pinmux:

// PERIPH_INSEL ranges from 0 to NUM_MIO_PADS + 2 -1}
//  0 and 1 are tied to value 0 and 1
pub const NUM_MIO_PADS: usize = ${top["pinmux"]["io_counts"]["muxed"]["pads"]};
pub const NUM_DIO_PADS: usize = ${top["pinmux"]["io_counts"]["dedicated"]["inouts"] + \
                       top["pinmux"]["io_counts"]["dedicated"]["inputs"] + \
                       top["pinmux"]["io_counts"]["dedicated"]["outputs"] };

pub const PINMUX_MIO_PERIPH_INSEL_IDX_OFFSET: usize = 2;
pub const PINMUX_PERIPH_OUTSEL_IDX_OFFSET: usize = 3;

/// Pinmux Peripheral Input.
${helper.pinmux_peripheral_in.render(gen_cast=True)}

/// Pinmux MIO Input Selector.
${helper.pinmux_insel.render(gen_cast=True)}

/// Pinmux MIO Output.
${helper.pinmux_mio_out.render(gen_cast=True)}

/// Pinmux Peripheral Output Selector.
${helper.pinmux_outsel.render(gen_cast=True)}

/// Dedicated Pad Selects
${helper.direct_pads.render(gen_cast=True)}

/// Muxed Pad Selects
${helper.muxed_pads.render(gen_cast=True)}
% endif
% if has_pwrmgr:

/// Power Manager Wakeup Signals
${helper.pwrmgr_wakeups.render()}
% endif
% if has_rstmgr:

/// Reset Manager Software Controlled Resets
${helper.rstmgr_sw_rsts.render()}
% endif
% if has_pwrmgr:

/// Power Manager Reset Request Signals
${helper.pwrmgr_reset_requests.render()}
% endif
% if has_clkmgr:

/// Clock Manager Software-Controlled ("Gated") Clocks.
///
/// The Software has full control over these clocks.
${helper.clkmgr_gateable_clocks.render()}

/// Clock Manager Software-Hinted Clocks.
///
/// The Software has partial control over these clocks. It can ask them to stop,
/// but the clock manager is in control of whether the clock actually is stopped.
${helper.clkmgr_hintable_clocks.render()}
% endif
% for (subspace_name, description, subspace_range) in helper.subranges:

/// ${subspace_name.upper()} Region
///
% for l in textwrap.wrap(description, 76, break_long_words=False):
/// ${l}
% endfor
pub const ${subspace_range.base_addr_name().as_rust_const()}: usize = ${"0x{:X}".format(subspace_range.base_addr)};
pub const ${subspace_range.size_bytes_name().as_rust_const()}: usize = ${"0x{:X}".format(subspace_range.size_bytes)};
% endfor
