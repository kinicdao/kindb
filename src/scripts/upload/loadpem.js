// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Ed25519KeyIdentity } from '@dfinity/identity';
import { Secp256k1KeyIdentity } from "@dfinity/identity-secp256k1";

import fs from 'fs';
import path from 'path';
import pemfile from 'pem-file';



// import identity from local pem file
// See https://github.com/ZenVoich/mops/blob/main/cli/pem.js
export function importIdentity(name) {
    let identity = decodeFile(path.resolve(process.env.HOME, '.config/dfx/identity', name, 'identity.pem'))
    return identity
};
function decodeFile(file) {
	const rawKey = fs.readFileSync(file).toString();
	return decode(rawKey);
};
function decode(rawKey) {
	var buf = pemfile.decode(rawKey);
	if (rawKey.includes('EC PRIVATE KEY')) {
		if (buf.length != 118) {
			throw 'expecting byte length 118 but got ' + buf.length;
		}
		return Secp256k1KeyIdentity.fromSecretKey(buf.slice(7, 39));
	}
	if (buf.length != 85) {
		throw 'expecting byte length 85 but got ' + buf.length;
	}
	let secretKey = Buffer.concat([buf.slice(16, 48), buf.slice(53, 85)]);
	return Ed25519KeyIdentity.fromSecretKey(secretKey);
}