import type { Metadata } from "next";
import { Inter, Architects_Daughter } from "next/font/google";
import "./globals.css";
import Navbar from "@/components/navbar";
import ContextProvider from "@/context/wagmi-provider";
import { headers } from "next/headers";
import ScrollbarSize from "@/components/scrollbar-size";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});
const handwriting = Architects_Daughter({ 
  weight: "400", 
  subsets: ["latin"],
  variable: "--font-handwriting"
});

export const metadata: Metadata = {
  title: "Dream",
  description: "Dream finance application",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const headersList = await headers();
  const cookies = headersList.get("cookie");

  return (
    <html lang="en">
      <body className={`${inter.variable} ${handwriting.variable} antialiased`}>
        <div className="max-w-5xl mx-auto">
          <ContextProvider cookies={cookies}>
            <ScrollbarSize />
            <Navbar />
            {children}
          </ContextProvider>
        </div>
        
        <div className="absolute inset-x-0 top-[calc(55%-13rem)] -z-10 transform-gpu overflow-hidden blur-3xl sm:top-[calc(57%-30rem)] overflow-hidden">
          <div 
            className="relative left-[calc(40%+3rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 bg-gradient-to-tr from-primary to-primary/60 opacity-30 animate-pulse-slow sm:left-[calc(40%+36rem)] sm:w-[72.1875rem]" 
            style={{
              clipPath: "polygon(74% 44.1%, 99.9% 61.6%, 97.4% 26.9%, 85.4% 0.1%, 80.6% 2%, 72.4% 32.5%, 97.4% 74.87%, 27.05% 96.87%, 89% 14.45%, 47.3% 38.12%, 43.22% 13.63%, 7.12% 66.77%, 23.49% 8.79%, 36.29% 93.75%, 0% 64.9%, 17.8% 100%, 5.43% 19.43%, 76% 97.7%, 65.5% 49.7%)"
            }}
          ></div>
        </div>
      </body>
    </html>
  );
}
