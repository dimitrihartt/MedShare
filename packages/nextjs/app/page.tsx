"use client";

import Image from "next/image";
import Link from "next/link";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
// import { BugAntIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold">MedShare System dApp</span>
          </h1>
          <div className="flex justify-center items-center space-x-2 flex-col sm:flex-row">
            <p className="my-2 font-medium">Connected Address:</p>
            <Address address={connectedAddress} />
          </div>
          <p className="text-center text-lg">
            Get started by filling out the form and interacting with our{" "}
            <code className="italic bg-base-300 text-base font-bold max-w-full break-words break-all inline-block">
              Smart Contract
            </code>
          </p>

          <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <div className="flex relative w-10 h-10">
                <Image alt="Family Logo" className="cursor-pointer" fill src="/ic_family_account.png" />
              </div>
              <p>
                MedShare works with{" "}
                <Link href="/debug" passHref className="link">
                  families
                </Link>{" "}
                all around the world.
              </p>
            </div>
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <div className="flex relative w-10 h-10">
                <Image alt="Family Logo" className="cursor-pointer" fill src="/ic_hospitals_directory.png" />
              </div>
              <p>
                Many hospitals and medical professionals are{" "}
                <Link href="/blockexplorer" passHref className="link">
                  Partnering
                </Link>{" "}
                with us.
              </p>
            </div>
          </div>

          <p className="text-center text-lg">
            Learn more about our solution for a better{" "}
            <code className="italic bg-base-300 text-base font-bold max-w-full break-words break-all inline-block">
              Health Care System
            </code>{" "}
            in our Docs at the{" "}
            <Link href="https://www.shalomempire.com/v/medshare-guide" passHref className="link">
              MedShare Guide
            </Link>
            .
          </p>
        </div>

        <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              {/* <BugAntIcon className="h-8 w-8 fill-secondary" /> */}
              <div className="flex relative w-10 h-10">
                <Image
                  alt="Search for a doctor or specialty"
                  className="cursor-pointer"
                  fill
                  src="/ic_doctors_directory.png"
                />
              </div>
              <p>
                You can search for a doctor or for a specialty in our{" "}
                <Link href="/debug" passHref className="link">
                  Medical Directory
                </Link>{" "}
                tab.
              </p>
            </div>
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              {/* <MagnifyingGlassIcon className="h-8 w-8 fill-secondary" /> */}
              <div className="flex relative w-10 h-10">
                <Image
                  alt="Search for a doctor or specialty"
                  className="cursor-pointer"
                  fill
                  src="/ic_call_center.png"
                />
              </div>
              <p>
                If you have any doubt please don&apos;t hesitate to{" "}
                <Link href="https://wa.me/5561981202811" passHref className="link">
                  give as a call,
                </Link>{" "}
                please.
              </p>
            </div>
          </div>
          <p className="text-center text-lg">
            MedShare is another{" "}
            <code className="italic bg-base-300 text-base font-bold max-w-full break-words break-all inline-block">
              ShalomEmpire.com
            </code>{" "}
            company.
          </p>
        </div>
      </div>
    </>
  );
};

export default Home;
